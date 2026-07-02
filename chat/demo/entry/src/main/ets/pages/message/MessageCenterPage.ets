/**
 * 消息中心页（对齐 Android `MessageCenterActivity`）。
 *
 * 功能：搜索、下拉刷新、上拉加载、左滑删除、点击进入详情；
 * 从详情返回后同步本地已读状态（消除未读红点）。
 */
import router from '@ohos.router';
import { Prompt } from '@kit.ArkUI';
import { deleteMessage, getMessageList } from '../../api/MessageApi';
import { MessageInfo } from '../../bean/message/MessageInfo';
import { MessageConstants } from '../../utils/MessageConstants';
import { MessageReadState } from '../../manager/MessageReadState';
import { MessageInfoHelper } from '../../utils/MessageInfoHelper';
import { MessageTimeUtil } from '../../utils/MessageTimeUtil';
import { WindowImmersiveHelper } from '../../utils/WindowImmersiveHelper';

/** 页面主背景色 */
const PAGE_BG = '#FFFFFF';
/** 列表区域背景色 */
const LIST_BG = '#F5F5F7';

/** 路由参数：详情页返回时携带的已读消息 id */
interface MessageCenterRouteParams {
  readMsgId?: string;
}

@Entry
@Component
struct MessageCenterPage {
  // ---------- 布局 inset ----------
  /** 状态栏占位高度（vp） */
  @State statusBarInsetVp: number = 0;
  /** 导航栏占位高度（vp） */
  @State navigationBarInsetVp: number = 0;

  // ---------- 搜索 ----------
  /** 已提交给接口的搜索关键字 */
  @State searchKeyword: string = '';
  /** 搜索框当前输入内容 */
  @State searchInput: string = '';
  /** 是否显示搜索框右侧清空按钮 */
  @State showClearSearch: boolean = false;

  // ---------- 列表与分页 ----------
  /** 当前展示的消息列表 */
  @State messageList: MessageInfo[] = [];
  /** 下拉刷新中 */
  @State isRefreshing: boolean = false;
  /** 上拉加载更多中 */
  @State isLoadingMore: boolean = false;
  /** 是否已无更多数据 */
  @State noMore: boolean = false;
  /** 列表是否为空（用于展示空态） */
  @State listEmpty: boolean = false;

  /** 当前请求页码，从 1 开始 */
  private currentPage: number = 1;
  /** 是否正在请求列表（防重复请求） */
  private isLoading: boolean = false;
  /**
   * 最近一次打开详情的消息 id。
   * 详情返回时若 router 传参失败，用此 id 兜底标记已读。
   */
  private lastOpenedMsgId: string = '';

  /** 首次进入：沉浸式布局 + 拉取第一页 */
  aboutToAppear(): void {
    void this.applyImmersiveLayout();
    void this.refreshList();
  }

  /**
   * 页面重新显示（含从详情返回）。
   * 延迟一帧同步已读，避免早于 router.back 传参。
   */
  onPageShow(): void {
    void this.applyImmersiveLayout();
    setTimeout(() => {
      this.applyReadStatusFromDetail();
    }, 0);
  }

  /**
   * 从详情返回后，将对应消息本地标为已读并刷新列表 UI。
   * 读取顺序：MessageReadState → router.getParams → lastOpenedMsgId
   */
  private applyReadStatusFromDetail(): void {
    let readMsgId = MessageReadState.consumePendingRead();
    if (readMsgId.length === 0) {
      const params = router.getParams() as MessageCenterRouteParams;
      readMsgId = MessageInfoHelper.normalizeId(params?.readMsgId);
    }
    if (readMsgId.length === 0 && this.lastOpenedMsgId.length > 0) {
      readMsgId = this.lastOpenedMsgId;
    }
    if (readMsgId.length === 0) {
      return;
    }
    this.lastOpenedMsgId = '';
    this.messageList = MessageInfoHelper.markAsRead(this.messageList, readMsgId);
  }

  /** 沉浸式状态栏 + 读取系统栏 inset */
  private async applyImmersiveLayout(): Promise<void> {
    const ctx = getContext(this);
    await WindowImmersiveHelper.enableImmersiveStatusBar(ctx);
    this.statusBarInsetVp = await WindowImmersiveHelper.getStatusBarInsetVp(ctx);
    this.navigationBarInsetVp = await WindowImmersiveHelper.getNavigationBarInsetVp(ctx);
  }

  /** 下拉刷新：重置页码并请求第一页 */
  private async refreshList(): Promise<void> {
    this.currentPage = 1;
    this.noMore = false;
    await this.loadPage(true);
  }

  /** 列表滑到底部：加载下一页 */
  private async loadMore(): Promise<void> {
    if (this.noMore || this.isLoading || this.isLoadingMore) {
      return;
    }
    this.currentPage += 1;
    await this.loadPage(false);
  }

  /**
   * 请求一页列表数据。
   * @param isRefresh true=刷新（替换列表），false=加载更多（追加）
   */
  private async loadPage(isRefresh: boolean): Promise<void> {
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    if (isRefresh) {
      this.isRefreshing = true;
    } else {
      this.isLoadingMore = true;
    }

    try {
      const response = await getMessageList({
        pageNum: this.currentPage,
        pageSize: MessageConstants.DEFAULT_PAGE_SIZE,
        keyword: this.searchKeyword,
      });
      const rawList = response?.list ?? [];
      const pageList: MessageInfo[] = [];
      for (let i = 0; i < rawList.length; i++) {
        pageList.push(MessageInfoHelper.normalize(rawList[i]));
      }
      if (isRefresh) {
        this.messageList = pageList;
      } else {
        this.messageList = this.messageList.concat(pageList);
      }
      this.listEmpty = this.messageList.length === 0;
      if (pageList.length < MessageConstants.DEFAULT_PAGE_SIZE) {
        this.noMore = true;
      }
    } catch (err) {
      console.error(`MessageCenterPage loadPage failed: ${JSON.stringify(err)}`);
      if (!isRefresh) {
        this.currentPage = Math.max(1, this.currentPage - 1);
      }
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
      this.isLoadingMore = false;
    }
  }

  /** 键盘搜索：提交关键字并刷新列表 */
  private onSearchSubmit(): void {
    this.searchKeyword = this.searchInput.trim();
    void this.refreshList();
  }

  /** 清空搜索框并重新拉取全量列表 */
  private onClearSearch(): void {
    this.searchInput = '';
    this.searchKeyword = '';
    this.showClearSearch = false;
    void this.refreshList();
  }

  /**
   * 打开消息详情页。
   * @param message 被点击的列表项
   */
  private openMessageDetail(message: MessageInfo): void {
    const msgId = MessageInfoHelper.normalizeId(message.id);
    if (msgId.length === 0) {
      return;
    }
    this.lastOpenedMsgId = msgId;
    router.pushUrl({
      url: 'pages/message/MessageDetailPage',
      params: { msgId: msgId },
    }).catch((err: Error) => {
      console.error(`open MessageDetailPage failed: ${JSON.stringify(err)}`);
    });
  }

  /** 左滑删除：弹出二次确认框 */
  private confirmDeleteMessage(message: MessageInfo, index: number): void {
    AlertDialog.show({
      title: '删除消息',
      message: '确定要删除该条消息吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        },
      },
      secondaryButton: {
        value: '确定',
        fontColor: '#006EFF',
        action: () => {
          void this.performDeleteMessage(message, index);
        },
      },
    });
  }

  /**
   * 调用删除接口并从列表移除该项。
   * @param message 待删除消息
   * @param index   在 messageList 中的下标
   */
  private async performDeleteMessage(message: MessageInfo, index: number): Promise<void> {
    if (!message.id || message.id.length === 0) {
      return;
    }
    try {
      await deleteMessage(message.id);
      const next = [...this.messageList];
      if (index >= 0 && index < next.length) {
        next.splice(index, 1);
        this.messageList = next;
        this.listEmpty = this.messageList.length === 0;
      }
    } catch (err) {
      Prompt.showToast({ message: '删除失败' });
      console.error(`deleteMessage failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 根据 bizType 返回列表左侧业务图标。
   * @returns 图标 Resource，无匹配类型时返回 null（不展示图标与红点）
   */
  private getBizTypeIcon(bizType: string): Resource | null {
    if (bizType === 'COUPON') {
      return $r('app.media.left_icon_coupon');
    }
    if (bizType === 'TRAVEL') {
      return $r('app.media.icon_trip');
    }
    if (bizType === 'ORDER') {
      return $r('app.media.icon_order');
    }
    return null;
  }

  build() {
    Column() {
      this.TitleBarBuilder()
      this.SearchBarBuilder()
      Refresh({ refreshing: this.isRefreshing }) {
        List() {
          if (this.listEmpty && !this.isRefreshing) {
            ListItem() {
              this.EmptyStateBuilder()
            }
          } else {
            ForEach(this.messageList, (message: MessageInfo, index: number) => {
              ListItem() {
                this.MessageListItemBuilder(message)
              }
              .swipeAction({ end: this.DeleteSwipeBuilder(() => {
                this.confirmDeleteMessage(message, index);
              }) })
              .onClick(() => {
                this.openMessageDetail(message);
              })
            }, (message: MessageInfo) => MessageInfoHelper.listItemKey(message))
          }

          if (this.noMore && this.messageList.length > 0) {
            ListItem() {
              this.FooterBuilder()
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 14, right: 14 })
        .backgroundColor(LIST_BG)
        .onReachEnd(() => {
          void this.loadMore();
        })
      }
      .width('100%')
      .layoutWeight(1)
      .onRefreshing(() => {
        void this.refreshList();
      })
    }
    .width('100%')
    .height('100%')
    .padding({
      top: this.statusBarInsetVp,
      bottom: this.navigationBarInsetVp,
    })
    .backgroundColor(PAGE_BG)
  }

  /** 顶部标题栏：返回 + 「消息中心」 */
  @Builder
  TitleBarBuilder() {
    Row() {
      Image($r('app.media.back_icon'))
        .width(24)
        .height(24)
        .onClick(() => {
          router.back();
        })

      Text('消息中心')
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

  /** 搜索栏：输入框 + 清空按钮 */
  @Builder
  SearchBarBuilder() {
    Stack({ alignContent: Alignment.End }) {
      TextInput({ text: this.searchInput, placeholder: '请搜索你想要的内容' })
        .width('100%')
        .height(40)
        .fontSize(16)
        .fontColor('#000000')
        .placeholderColor('#B0B1B8')
        .backgroundColor('#F3F3F6')
        .borderRadius(8)
        .padding({ left: 12, right: 40 })
        .onChange((value: string) => {
          this.searchInput = value;
          this.showClearSearch = value.length > 0;
        })
        .onSubmit(() => {
          this.onSearchSubmit();
        })

      if (this.showClearSearch) {
        Text('×')
          .fontSize(22)
          .fontColor('#8D8E99')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onClearSearch();
          })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .backgroundColor('#FFFFFF')
  }

  /**
   * 单条消息卡片（对齐 Android `message_center_list_item`）。
   * @param message 列表数据项
   */
  @Builder
  MessageListItemBuilder(message: MessageInfo) {
    Column() {
      Row() {
        Row() {
          if (this.getBizTypeIcon(message.bizType) !== null) {
            Stack() {
              Image(this.getBizTypeIcon(message.bizType)!)
                .width(20)
                .height(20)
              // 未读红点：叠在图标右上角
              if (!MessageInfoHelper.isMessageRead(message.isRead)) {
                Circle()
                  .width(6)
                  .height(6)
                  .fill('#FF3B30')
                  .position({ x: 14, y: 0 })
              }
            }
            .width(26)
            .height(26)
            .margin({ right: 3 })
            .flexShrink(0)
          }

          Text(message.title)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        .constraintSize({ minWidth: 0 })

        Text(MessageTimeUtil.formatListTime(message.createTime))
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 8 })
          .flexShrink(0)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(message.content)
        .fontSize(14)
        .fontColor('#666666')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
        .width('100%')
    }
    .width('100%')
    .padding(13)
    .margin({ top: 5, bottom: 5 })
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .clip(true)
    .shadow({
      radius: 4,
      color: '#14000000',
      offsetX: 0,
      offsetY: 2,
    })
  }

  /** 左滑露出的删除按钮区域 */
  @Builder
  DeleteSwipeBuilder(onDelete: () => void) {
    Row() {
      Text('删除')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(60)
        .height('100%')
        .backgroundColor('#FF3B30')
        .onClick(() => {
          onDelete();
        })
    }
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  /** 列表底部：没有更多了 */
  @Builder
  FooterBuilder() {
    Text('—— 暂时没有更多了 ——')
      .fontSize(12)
      .fontColor('#B0B1B8')
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ top: 16, bottom: 16 })
  }

  /** 列表空态 */
  @Builder
  EmptyStateBuilder() {
    Column() {
      Text('暂无消息')
        .fontSize(14)
        .fontColor('#B0B1B8')
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
