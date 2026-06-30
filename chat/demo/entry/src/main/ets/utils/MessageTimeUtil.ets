/**
 * 消息模块时间格式化（对齐 Android `TimeUtil.yMdHmS2MdHm`）。
 */
export class MessageTimeUtil {
  /**
   * 列表/详情时间展示：yyyy-MM-dd HH:mm:ss → MM-dd HH:mm。
   * @param dateTimeStr 接口原始时间字符串
   */
  static formatListTime(dateTimeStr: string): string {
    if (!dateTimeStr || dateTimeStr.length === 0) {
      return '';
    }
    const normalized = dateTimeStr.trim();
    if (normalized.length >= 16) {
      return `${normalized.substring(5, 10)} ${normalized.substring(11, 16)}`;
    }
    if (normalized.length >= 10) {
      return normalized.substring(5, 10);
    }
    return normalized;
  }
}
