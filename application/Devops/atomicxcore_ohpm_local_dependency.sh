#!/usr/bin/env bash
#
# 将 harmony/application 的 AtomicXCore 依赖统一切换到 harmony/SDK 下的本地 HAR。
# 可从任意目录调用；使用 --help 查看参数。
#

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="$APP_ROOT/../SDK"
ROOT_PKG="$APP_ROOT/oh-package.json5"
ENTRY_PKG="$APP_ROOT/entry/oh-package.json5"
ENTRY_LOCK="$APP_ROOT/entry/oh-package-lock.json5"
BACKUP_SUFFIX=".appbak"
REQUESTED_HAR=""
FORCE=0
RESTORE=0

usage() {
  cat <<'USAGE'
用法: atomicxcore_ohpm_local_dependency.sh [--har <SDK内文件名>] [--force]
      atomicxcore_ohpm_local_dependency.sh --restore

作用:
  将根 overrides 和 entry 的 @tencentcloud/atomicxcore 统一切换为
  harmony/SDK 下的本地 HAR，并执行 ohpm install --all。

参数:
  --har <文件名>  使用 harmony/SDK 中指定的 atomicxcore_*.har；
                  缺省时按版本选择最高者。
  --force         即使当前依赖已指向目标 HAR，也重新写入并安装依赖。
  --restore       恢复首次切换前备份的 oh-package 与 entry 锁文件。
  --help          显示本说明。

防呆:
  - 校验 HAR 包名必须是 @tencentcloud/atomicxcore。
  - 首次修改前在同目录写入 .appbak 备份，不覆盖已有备份。
  - 恢复后重新执行 ohpm install --all；失败时保留备份。
  - 本地 HAR 不移动、不删除。

切换后请在 DevEco 执行 Clean Project 再构建，避免增量字节码混用。
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

find_ohpm() {
  if [ -n "${OHPM_BIN:-}" ]; then
    [ -x "$OHPM_BIN" ] || die "OHPM_BIN 不可执行: $OHPM_BIN"
    printf '%s\n' "$OHPM_BIN"
    return
  fi
  if command -v ohpm >/dev/null 2>&1; then
    command -v ohpm
    return
  fi
  local candidate="/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm"
  [ -x "$candidate" ] || die "找不到 ohpm，请设置 OHPM_BIN 或将 ohpm 加入 PATH"
  printf '%s\n' "$candidate"
}

select_har() {
  if [ -n "$REQUESTED_HAR" ]; then
    [[ "$REQUESTED_HAR" =~ ^atomicxcore_[0-9.]+\.har$ ]] ||
      die "--har 只接受 SDK 目录内的 atomicxcore_<版本>.har 文件名"
    printf '%s\n' "$SDK_DIR/$REQUESTED_HAR"
    return
  fi
  [ -d "$SDK_DIR" ] || die "未找到 SDK 目录: $SDK_DIR"
  find "$SDK_DIR" -maxdepth 1 -type f -name 'atomicxcore_*.har' -print | sort -V | tail -n 1
}

package_version() {
  tar -xOf "$1" package/oh-package.json5 2>/dev/null |
    sed -nE 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p'
}

validate_har() {
  local har="$1" metadata
  [ -f "$har" ] || die "本地 HAR 不存在: $har"
  [[ "$(basename "$har")" =~ ^atomicxcore_[0-9.]+\.har$ ]] || die "HAR 文件名不符合 atomicxcore_<版本>.har: $har"
  metadata="$(tar -xOf "$har" package/oh-package.json5 2>/dev/null)" || die "无法读取 HAR 元数据: $har"
  printf '%s' "$metadata" | grep -qE '"name"[[:space:]]*:[[:space:]]*"@tencentcloud/atomicxcore"' ||
    die "HAR 包名不是 @tencentcloud/atomicxcore: $har"
}

backup_file() {
  local file="$1"
  [ -f "$file" ] || return 0
  if [ ! -f "${file}${BACKUP_SUFFIX}" ]; then
    cp "$file" "${file}${BACKUP_SUFFIX}" || die "备份失败: $file"
    printf '[ok] 已备份 %s\n' "${file#$APP_ROOT/}"
  fi
}

write_dependency() {
  local file="$1" spec="$2"
  sed -i '' -E "s|(\"@tencentcloud/atomicxcore\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"${spec}\"|" "$file"
  grep -qF "\"@tencentcloud/atomicxcore\": \"$spec\"" "$file" || die "依赖切换失败: $file"
  printf '[ok] %s -> %s\n' "${file#$APP_ROOT/}" "$spec"
}

install_dependencies() {
  local ohpm="$1"
  printf '\n== 安装 ohpm 依赖 ==\n'
  (cd "$APP_ROOT" && "$ohpm" install --all)
}

restore() {
  local ohpm
  ohpm="$(find_ohpm)"
  [ -f "${ROOT_PKG}${BACKUP_SUFFIX}" ] || die "缺少备份: ${ROOT_PKG}${BACKUP_SUFFIX}"
  [ -f "${ENTRY_PKG}${BACKUP_SUFFIX}" ] || die "缺少备份: ${ENTRY_PKG}${BACKUP_SUFFIX}"
  cp "${ROOT_PKG}${BACKUP_SUFFIX}" "$ROOT_PKG"
  cp "${ENTRY_PKG}${BACKUP_SUFFIX}" "$ENTRY_PKG"
  if [ -f "${ENTRY_LOCK}${BACKUP_SUFFIX}" ]; then
    cp "${ENTRY_LOCK}${BACKUP_SUFFIX}" "$ENTRY_LOCK"
  fi
  install_dependencies "$ohpm"
  rm -f "${ROOT_PKG}${BACKUP_SUFFIX}" "${ENTRY_PKG}${BACKUP_SUFFIX}" "${ENTRY_LOCK}${BACKUP_SUFFIX}"
  printf '\n已恢复切换前依赖。请在 DevEco 执行 Clean Project 后重新构建。\n'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --har)
      [ $# -ge 2 ] || die "--har 缺少文件名"
      REQUESTED_HAR="$2"
      shift 2
      ;;
    -f | --force)
      FORCE=1
      shift
      ;;
    -r | --restore)
      RESTORE=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

[ "$RESTORE" -eq 0 ] || { restore; exit 0; }
[ -f "$ROOT_PKG" ] || die "未找到 $ROOT_PKG"
[ -f "$ENTRY_PKG" ] || die "未找到 $ENTRY_PKG"
command -v tar >/dev/null 2>&1 || die "缺少 tar"

HAR="$(select_har)"
[ -n "$HAR" ] || die "$SDK_DIR 下没有 atomicxcore_*.har"
validate_har "$HAR"
HAR_NAME="$(basename "$HAR")"
ROOT_SPEC="file:../SDK/$HAR_NAME"
ENTRY_SPEC="file:../../SDK/$HAR_NAME"
OHPM="$(find_ohpm)"

printf 'AtomicXCore HAR: %s\n' "$HAR"
printf 'AtomicXCore 包版本: %s\n' "$(package_version "$HAR")"

if [ "$FORCE" -eq 0 ] &&
  grep -qF "\"@tencentcloud/atomicxcore\": \"$ROOT_SPEC\"" "$ROOT_PKG" &&
  grep -qF "\"@tencentcloud/atomicxcore\": \"$ENTRY_SPEC\"" "$ENTRY_PKG"; then
  printf '[skip] 根 overrides 与 entry 已指向目标 HAR\n'
else
  backup_file "$ROOT_PKG"
  backup_file "$ENTRY_PKG"
  backup_file "$ENTRY_LOCK"
  write_dependency "$ROOT_PKG" "$ROOT_SPEC"
  write_dependency "$ENTRY_PKG" "$ENTRY_SPEC"
fi

install_dependencies "$OHPM"
printf '\n本地 AtomicXCore 依赖已就位。请在 DevEco 执行 Clean Project 后重新构建。\n'
printf '恢复切换前配置: bash %s --restore\n' "$0"
