import { BusinessError } from '@kit.BasicServicesKit';
import { ComponentContent, promptAction } from '@kit.ArkUI';
import { UIContext } from '@ohos.arkui.UIContext';

/**
 * 与 Android 端 XToastUtils.toast（XUI XToast.normal + Config alpha 200）视觉对齐：
 * toast_normal_tint #353A3E + alpha 200 → #C8353A3E；文字 #FFFFFF。
 */
interface XToastNormalParams {
  message: string | Resource;
}

@Builder
function buildXToastNormalContent(params: XToastNormalParams) {
  Row() {
    Text(params.message)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .lineHeight(14 * 1.57)
      .textAlign(TextAlign.Start)
      .maxLines(10)
      .textOverflow({ overflow: TextOverflow.Clip })
  }
  .padding({
    left: 16,
    right: 16,
    top: 9,
    bottom: 9
  })
  .backgroundColor('#C8353A3E')
  .borderRadius(8)
  .shadow({
    radius: 12,
    color: '#40000000',
    offsetX: 0,
    offsetY: 4
  })
  .constraintSize({
    minHeight: 40,
    maxWidth: 340
  })
  .justifyContent(FlexAlign.Center)
}

export class XToastUtils {
  private static uiCtx: UIContext | null = null;
  private static contentNode: ComponentContent<XToastNormalParams> | null = null;
  private static dismissTimer: number | null = null;

  /**
   * 居中短时提示，默认约 2s（对齐 LENGTH_SHORT 常用时长）。
   */
  static toast(message: string | Resource, uiContext: UIContext, durationMs: number = 2000): void {
    if (XToastUtils.dismissTimer !== null) {
      clearTimeout(XToastUtils.dismissTimer);
      XToastUtils.dismissTimer = null;
    }

    XToastUtils.closeDialogSync().then(() => {
      XToastUtils.uiCtx = uiContext;
      const params: XToastNormalParams = { message: message };
      XToastUtils.contentNode =
        new ComponentContent(uiContext, wrapBuilder(buildXToastNormalContent), params);

      const options: promptAction.BaseDialogOptions = {
        alignment: DialogAlignment.Center,
        autoCancel: false,
        maskColor: Color.Transparent,
        isModal: false
      };

      uiContext.getPromptAction()
        .openCustomDialog(XToastUtils.contentNode, options)
        .then(() => {
          if (durationMs > 0) {
            XToastUtils.dismissTimer = setTimeout(() => {
              XToastUtils.close();
            }, durationMs);
          }
        })
        .catch((error: BusinessError) => {
          console.error(`XToastUtils openCustomDialog failed: ${error.code} ${error.message}`);
        });
    });
  }

  static close(): void {
    if (XToastUtils.dismissTimer !== null) {
      clearTimeout(XToastUtils.dismissTimer);
      XToastUtils.dismissTimer = null;
    }

    if (XToastUtils.contentNode !== null && XToastUtils.uiCtx !== null) {
      XToastUtils.uiCtx.getPromptAction()
        .closeCustomDialog(XToastUtils.contentNode)
        .then(() => {
          XToastUtils.contentNode = null;
        })
        .catch((error: BusinessError) => {
          console.error(`XToastUtils closeCustomDialog failed: ${error.code} ${error.message}`);
          XToastUtils.contentNode = null;
        });
    }
  }

  private static closeDialogSync(): Promise<void> {
    return new Promise((resolve) => {
      if (XToastUtils.dismissTimer !== null) {
        clearTimeout(XToastUtils.dismissTimer);
        XToastUtils.dismissTimer = null;
      }

      if (XToastUtils.contentNode !== null && XToastUtils.uiCtx !== null) {
        XToastUtils.uiCtx.getPromptAction()
          .closeCustomDialog(XToastUtils.contentNode)
          .then(() => {
            XToastUtils.contentNode = null;
            resolve();
          })
          .catch((_error: BusinessError) => {
            XToastUtils.contentNode = null;
            resolve();
          });
      } else {
        resolve();
      }
    });
  }
}
