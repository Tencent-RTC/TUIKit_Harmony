# 即时通信 IM

## 产品简介

即时通信 IM（Instant Messaging）基于 QQ 底层 IM 能力开发，仅需植入 IM SDK 即可轻松集成聊天、会话、群组、资料管理和直播弹幕能力，也支持通过信令消息与白板等其他产品打通，全面覆盖您的业务场景，支持各大平台小程序接入使用，全面满足通信需要。

## 集成方式

### 环境要求

- DevEco Studio NEXT Release 及以上
- HarmonyOS SDK API 12 及以上

### 下载安装

```shell
ohpm install @tencentcloud/imsdk
```

### 通过 har 引用

先将下载的 IM SDK 放在工程或模块目录，然后执行以下操作：

方式一：在 Terminal 窗口中，执行如下命令安装三方包，DevEco Studio 会自动在工程或模块的 `oh-package.json5` 中自动添加三方包依赖：

```shell
ohpm install ./imsdk-ohos-9.1.7818.har
```

方式二：在工程或模块的 `oh-package.json5` 中设置三方包依赖，配置示例如下：

```json5
{
  dependencies: {
    "@tencentcloud/imsdk": "file:./imsdk-ohos-9.1.7818.har",
  },
}
```

依赖设置完成后，需要执行 ohpm install 命令安装依赖包，依赖包会存储在工程或模块的 oh_modules 目录下:

```shell
ohpm install
```

### 设置权限

在模块的 `module.json5` 中，配置示例如下：

```json5
{
  module: {
    requestPermissions: [
      {
        name: "ohos.permission.GET_NETWORK_INFO",
      },
      {
        name: "ohos.permission.INTERNET",
      },
    ],
  },
}
```

## 交流与反馈

[点此进入 IM 社群](https://zhiliao.qq.com/s/c5GY7HIM62CK/cIRRTIIM62CF)，享有专业工程师的支持，解决您的难题。

## 相关链接

[下载 IM SDK](https://cloud.tencent.com/document/product/269/36887) | [集成 IM SDK](https://cloud.tencent.com/document/product/269/103558) | [运行 IM Demo](https://cloud.tencent.com/document/product/269/103557) | [API 文档](https://cloud.tencent.com/document/product/269/103559)
