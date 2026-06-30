/**
 * 消息详情页（对齐 Android `MessageDetailActivity`）。
 *
 * - 展示标题、时间、正文；
 * - 底部操作按钮：「查看详情」→ Flutter 业务页；「咨询」→ Toast 敬请期待；
 * - 返回列表时回传已读 msgId，供列表页消除红点。
 */
import router from '@ohos.router';
import { Prompt } from '@kit.ArkUI';
import { getMessageDetail } from '../../api/MessageApi';
import { MessageDetailActionBean } from '../../bean/message/MessageDetailActionBean';
import { MessageDetailBean } from '../../bean/message/MessageDetailBean';
import { MessageNavigatorManager } from '../../manager/MessageNavigatorManager';
import { MessageConstants } from '../../utils/MessageConstants';
import { MessageTimeUtil } from '../../utils/MessageTimeUtil';
import { MessageReadState } from '../../manager/MessageReadState';
import { WindowImmersiveHelper } from '../../utils/WindowImmersiveHelper';

/** 页面顶栏与底栏背景 */
const PAGE_BG = '#FFFFFF';
/** 正文滚动区背景 */
const BODY_BG = '#F5F5F7';

/** 路由入参：列表页传入的 msgId */
interface MessageDetailRouteParams {
  msgId?: string;
}

@Entry
@Component
struct MessageDetailPage {
  // ---------- 布局 inset ----------
  @State statusBarInsetVp: number = 0;
  @State navigationBarInsetVp: number = 0;

  // ---------- 详情展示 ----------
  /** 消息标题 */
  @State title: string = '';
  /** 格式化后的创建时间 */
  @State createTime: string = '';
  /** 消息正文 */
  @State content: string = '';
  /** 底部操作按钮列表 */
  @State actions: MessageDetailActionBean[] = [];

  // ---------- 加载状态 ----------
  /** 详情接口请求中 */
  @State isLoading: boolean = true;
  /** 加载失败（如无 msgId 或接口错误） */
  @State loadFailed: boolean = false;

  /** 当前消息 id，返回列表时用于标记已读 */
  private msgId: string = '';

  /**
   * 解析路由参数并拉取详情。
   * msgId 为空时直接返回上一页。
   */
  aboutToAppear(): void {
    void this.applyImmersiveLayout();
    const params = router.getParams() as MessageDetailRouteParams;
    this.msgId = params?.msgId ?? '';
    if (!this.msgId || this.msgId.length === 0) {
      this.loadFailed = true;
      this.isLoading = false;
      router.back();
      return;
    }
    void this.loadDetail(this.msgId);
  }

  /** 沉浸式状态栏 + 读取系统栏 inset */
  private async applyImmersiveLayout(): Promise<void> {
    const ctx = getContext(this);
    await WindowImmersiveHelper.enableImmersiveStatusBar(ctx);
    this.statusBarInsetVp = await WindowImmersiveHelper.getStatusBarInsetVp(ctx);
    this.navigationBarInsetVp = await WindowImmersiveHelper.getNavigationBarInsetVp(ctx);
  }

  /**
   * 请求消息详情并渲染到页面。
   * @param msgId 消息 id
   */
  private async loadDetail(msgId: string): Promise<void> {
    this.isLoading = true;
    this.loadFailed = false;
    try {
      const bean = await getMessageDetail(msgId);
      this.renderDetail(bean);
    } catch (err) {
      console.error(`MessageDetailPage loadDetail failed: ${JSON.stringify(err)}`);
      this.loadFailed = true;
      router.back();
    } finally {
      this.isLoading = false;
    }
  }

  /** 将接口数据写入 @State，驱动 UI 更新 */
  private renderDetail(bean: MessageDetailBean | null): void {
    if (!bean) {
      this.loadFailed = true;
      return;
    }
    this.title = bean.title ?? '';
    this.createTime = MessageTimeUtil.formatListTime(bean.createTime ?? '');
    this.content = bean.content ?? '';
    this.actions = bean.action ?? [];
  }

  /**
   * 底部按钮点击。
   * 咨询类 → Toast；查看详情类 → {@link MessageNavigatorManager}
   */
  private onActionClick(action: MessageDetailActionBean): void {
    const target = action.target ?? '';
    const name = action.name ?? '';
    if (MessageConstants.isConsultAction(target, name)) {
      Prompt.showToast({ message: '功能开发中，敬请期待' });
      return;
    }
    MessageNavigatorManager.handleAction(target, action.params);
  }

  /**
   * 带已读结果返回消息中心（对齐 Android `finishWithReadResult`）。
   * 通过 MessageReadState + router.back params 双通道通知列表页。
   */
  private finishWithReadResult(): void {
    if (this.msgId.length > 0) {
      MessageReadState.setPendingRead(this.msgId);
      router.back({
        url: 'pages/message/MessageCenterPage',
        params: { readMsgId: this.msgId },
      });
      return;
    }
    router.back();
  }

  build() {
    Column() {
      this.TitleBarBuilder()

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#006EFF')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (!this.loadFailed) {
        Scroll() {
          Column() {
            Column() {
              Text(this.title)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#131212')
                .width('100%')

              Text(this.createTime)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 3 })
                .width('100%')

              Text(this.content)
                .fontSize(14)
                .fontColor('#444444')
                .lineHeight(22)
                .margin({ top: 12 })
                .width('100%')
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 20,
              bottom: 20,
            })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .clip(true)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
        }
        .align(Alignment.Top)
        .backgroundColor(BODY_BG)
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)

        if (this.actions.length > 0) {
          this.ActionBarBuilder()
        }
      }
    }
    .width('100%')
    .height('100%')
    .padding({
      top: this.statusBarInsetVp,
      bottom: this.navigationBarInsetVp,
    })
    .backgroundColor(PAGE_BG)
  }

  /** 顶部标题栏：返回（触发已读回传）+ 「消息详情」 */
  @Builder
  TitleBarBuilder() {
    Row() {
      Image($r('app.media.back_icon'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.finishWithReadResult();
        })

      Text('消息详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#000000')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ right: 24 })
    }
    .width('100%')
    .height(60)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
  }

  /** 底部按钮之间的竖向分割线（对齐 Android divider_msg_detail_action） */
  @Builder
  ActionDividerBuilder() {
    Column()
      .width(1)
      .height(24)
      .backgroundColor('#E7E7E7')
      .margin({ left: 3, right: 3 })
  }

  /**
   * 单个底部按钮槽位：非首个按钮前插入分割线，按钮等分宽度。
   * @param action 按钮数据
   * @param index  在 actions 中的下标
   */
  @Builder
  ActionSlotBuilder(action: MessageDetailActionBean, index: number) {
    Row() {
      if (index > 0) {
        this.ActionDividerBuilder()
      }
      Button(action.name.length > 0 ? action.name : '操作')
        .type(ButtonType.Normal)
        .fontSize(16)
        .fontColor('#131212')
        .backgroundColor('#FFFFFF')
        .borderRadius(0)
        .layoutWeight(1)
        .height(48)
        .onClick(() => {
          this.onActionClick(action);
        })
    }
    .layoutWeight(1)
    .height(48)
    .alignItems(VerticalAlign.Center)
  }

  /** 底部固定操作栏：横向排列「查看详情」「咨询」等按钮 */
  @Builder
  ActionBarBuilder() {
    Row() {
      ForEach(this.actions, (action: MessageDetailActionBean, index: number) => {
        this.ActionSlotBuilder(action, index)
      }, (action: MessageDetailActionBean, index: number) => `${action.target}_${index}`)
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 30,
    })
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: -2,
    })
  }
}
