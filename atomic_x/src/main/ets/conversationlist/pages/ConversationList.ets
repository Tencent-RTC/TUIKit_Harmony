import {
  Avatar,
  AvatarSize,
  AvatarShape,
  AvatarBadge,
  AvatarBadgeConfig,
  AvatarBadgePosition,
  AvatarStatus,
  TextUtils,
  ThemeState,
  AvatarContentType,
  AppBuilderConfig,
  ConversationAction,
  ContextProvider,
  LanguageState,
  AlertDialog
} from '../../basecomponent/Index';
import { ConversationListStore, ConversationInfo, ConversationLoadOption, ConversationType, ReceiveMessageOption, ConversationListState, ConversationMarkType, GroupAtType, GroupAtInfo } from '@tencentcloud/atomicxcore';
import { ErrorInfo } from '@tencentcloud/atomicxcore';
import { LoginStore } from '@tencentcloud/atomicxcore';
import { GroupType } from '@tencentcloud/atomicxcore';
import { ConversationDialogAction, ConversationDialogAction as DialogAction } from './ConversationMoreDialog';
import { router } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { MessageUtils } from '../../messagelist/utils/MessageUtils';
import { EmojiDataManager, EmojiTextSegment } from '../../emojipicker/Index';
import { MessageStatus } from '@tencentcloud/atomicxcore';
import { ConversationActionConfigProtocol, ChatConversationActionConfig } from '../config/ConversationListConfig';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';

// Custom action interface for ConversationList
export interface ConversationCustomAction {
  title: string | Resource;
  iconName?: string | Resource;
  action: (conversation: ConversationInfo) => void;
}

interface ConversationMenuActionItem {
  text: string | Resource;
  dangerous: boolean;
  value: string;
}

class StableConversationListDataSource implements IDataSource {
  private items: ConversationInfo[] = [];
  private itemMap: Map<string, ConversationInfo> = new Map();
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): ConversationInfo | null {
    if (index < 0 || index >= this.items.length) {
      return null;
    }
    return this.items[index];
  }

  getIndex(conversationID: string): number {
    return this.items.findIndex((item: ConversationInfo) => item.conversationID === conversationID);
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  syncFromCore(coreItems: ConversationInfo[]): void {
    const previousItems = this.items;
    const nextItems: ConversationInfo[] = [];
    const nextMap: Map<string, ConversationInfo> = new Map();
    const changedIndexes: number[] = [];

    for (let index = 0; index < coreItems.length; index++) {
      const coreItem = coreItems[index];
      let stableItem = this.itemMap.get(coreItem.conversationID);
      if (!stableItem) {
        stableItem = coreItem;
      } else if (stableItem !== coreItem && this.copyFields(stableItem, coreItem)) {
        changedIndexes.push(index);
      }
      nextItems.push(stableItem);
      nextMap.set(coreItem.conversationID, stableItem);
    }

    const identityOrderUnchanged = this.hasSameIdentityOrder(previousItems, nextItems);
    this.items = nextItems;
    this.itemMap = nextMap;
    if (!identityOrderUnchanged) {
      this.notifyDataReload();
      return;
    }
    changedIndexes.forEach((index: number) => {
      this.listeners.forEach((listener: DataChangeListener) => listener.onDataChange(index));
    });
  }

  private hasSameIdentityOrder(previousItems: ConversationInfo[], nextItems: ConversationInfo[]): boolean {
    if (previousItems.length !== nextItems.length) {
      return false;
    }
    for (let index = 0; index < previousItems.length; index++) {
      if (previousItems[index].conversationID !== nextItems[index].conversationID) {
        return false;
      }
    }
    return true;
  }

  private copyFields(target: ConversationInfo, source: ConversationInfo): boolean {
    const changed = target.type !== source.type ||
      target.groupType !== source.groupType ||
      target.avatarURL !== source.avatarURL ||
      target.title !== source.title ||
      target.lastMessage !== source.lastMessage ||
      target.draft !== source.draft ||
      target.unreadCount !== source.unreadCount ||
      target.isPinned !== source.isPinned ||
      target.receiveOption !== source.receiveOption ||
      target.groupAtInfoList !== source.groupAtInfoList ||
      target.conversationMarkList !== source.conversationMarkList ||
      target.conversationGroupList !== source.conversationGroupList ||
      target.rawConversation !== source.rawConversation;
    if (!changed) {
      return false;
    }

    target.type = source.type;
    target.groupType = source.groupType;
    target.avatarURL = source.avatarURL;
    target.title = source.title;
    target.lastMessage = source.lastMessage;
    target.draft = source.draft;
    target.unreadCount = source.unreadCount;
    target.isPinned = source.isPinned;
    target.receiveOption = source.receiveOption;
    target.groupAtInfoList = source.groupAtInfoList;
    target.conversationMarkList = source.conversationMarkList;
    target.conversationGroupList = source.conversationGroupList;
    target.rawConversation = source.rawConversation;
    return true;
  }

  private notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }
}

@Component
struct ConversationListRow {
  @ObjectLink conversation: ConversationInfo;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  onConversationClick?: (conversation: ConversationInfo) => void;
  @Prop isHighlighted: boolean = false;
  @State private rowGlobalY: number = 0;
  onLongPress?: (conversation: ConversationInfo, x: number, y: number) => void;

  build() {
    Stack() {
      Column() {
        Row() {
        Stack() {
          Avatar({
            content: {
              type: AvatarContentType.Image,
              name: this.conversation.title,
              url: this.conversation.avatarURL
            },
            avatarSize: AvatarSize.M,
            badge: this.getAvatarBadge()
          })
        }
        .margin({ right: 8 })

        Column() {
          Row() {
            Text(this.conversation.title || $r('app.string.conversationlist_title_placeholder'))
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeState.colors.textColorPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)

            Text(this.formatTimeFromTs(this.conversation.lastMessage?.timestamp ?? 0))
              .fontSize(12)
              .fontColor(this.themeState.colors.textColorSecondary)
              .margin({ left: 8 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            if (this.conversation.lastMessage?.status === MessageStatus.SENDING) {
              LoadingProgress()
                .width(12)
                .height(12)
                .margin({ right: 4 })
            }

            if (this.conversation.lastMessage?.isSentBySelf && this.conversation.lastMessage?.status === MessageStatus.SEND_FAIL) {
              Image($rawfile('messagelist/icon_message_send_error.svg'))
                .width(12)
                .height(12)
                .margin({ right: 4 })
            }

            this.buildMixedContent()

            if (this.conversation.receiveOption != ReceiveMessageOption.RECEIVE && this.conversation.groupType != GroupType.MEETING) {
              Image($rawfile('conversationlist/muted_icon.svg'))
                .width(16)
                .height(16)
                .fillColor(this.themeState.colors.textColorDisable)
                .margin({ left: 8 })
            }
          }
          .width('100%')
          .margin({ top: 4 })
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.onConversationClick?.(this.conversation);
      })
      .gesture(
        LongPressGesture({ repeat: false })
          .onAction(() => {
            this.onLongPress?.(this.conversation, 0, this.rowGlobalY);
          })
      )
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        this.rowGlobalY = Number(newValue.globalPosition.y);
      })

      Row() {
        Row()
          .layoutWeight(1)
          .height(0.5)
          .backgroundColor(this.themeState.colors.strokeColorSecondary)
      }
      .width('100%')
      .padding({ left: 64 })
      }
      .width('100%')
      .height(64.5)
      .backgroundColor(this.conversation.isPinned ? this.themeState.colors.bgColorInput : this.themeState.colors.bgColorOperate)

      if (this.isHighlighted) {
        Column()
          .width('100%')
          .height(64.5)
          .backgroundColor('rgba(0, 0, 0, 0.08)')
          .onClick(() => {
          })
      }
    }
    .width('100%')
  }

  private getAvatarBadge(): AvatarBadgeConfig {
    const hasUnread = (this.conversation.unreadCount ?? 0) > 0 ||
      this.conversation.conversationMarkList.some((mark: ConversationMarkType) => mark.contains(ConversationMarkType.unread));
    if (!hasUnread) {
      return { type: AvatarBadge.None };
    }
    if (this.conversation.receiveOption !== ReceiveMessageOption.RECEIVE) {
      return { type: AvatarBadge.Dot, position: AvatarBadgePosition.Up };
    }
    const unreadCount = this.conversation.unreadCount ?? 0;
    return {
      type: AvatarBadge.Text,
      text: unreadCount > 0 ? (unreadCount > 99 ? '99+' : `${unreadCount}`) : '1',
      position: AvatarBadgePosition.Up
    };
  }

  private formatTimeFromTs(timestamp: number): string | Resource {
    if (!timestamp || timestamp <= 0) {
      return '';
    }

    const date = new Date(timestamp * 1000);
    const now = new Date();
    const getWeekOfMonth = (targetDate: Date): number => {
      const firstDayOfMonth = new Date(targetDate.getFullYear(), targetDate.getMonth(), 1);
      const firstDayOfWeek = firstDayOfMonth.getDay();
      return Math.ceil((targetDate.getDate() + firstDayOfWeek) / 7);
    };
    const isChineseLanguage = this.languageState.getLanguage().toLowerCase().startsWith('zh');
    const shortDate = isChineseLanguage
      ? `${date.getMonth() + 1}月${date.getDate()}日`
      : `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear().toString().slice(-2)}`;
    const fullDate = isChineseLanguage
      ? `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
      : shortDate;

    if (now.getFullYear() !== date.getFullYear()) {
      return fullDate;
    }
    if (now.getMonth() !== date.getMonth()) {
      return shortDate;
    }
    if (getWeekOfMonth(now) !== getWeekOfMonth(date)) {
      return shortDate;
    }
    if (now.getDate() !== date.getDate()) {
      switch (date.getDay()) {
        case 0:
          return $r('app.string.sunday');
        case 1:
          return $r('app.string.monday');
        case 2:
          return $r('app.string.tuesday');
        case 3:
          return $r('app.string.wednesday');
        case 4:
          return $r('app.string.thursday');
        case 5:
          return $r('app.string.friday');
        case 6:
          return $r('app.string.saturday');
        default:
          return '';
      }
    }
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  private getDisplaySubTitle(): string | Resource {
    if (this.hasDraft()) {
      return this.conversation.draft ?? '';
    }
    const abstract = MessageUtils.getMessageAbstract(this.conversation.lastMessage);
    if (this.conversation.receiveOption !== ReceiveMessageOption.RECEIVE && (this.conversation.unreadCount ?? 0) > 0) {
      const abstractText = typeof abstract === 'string'
        ? abstract
        : MessageUtils.getMessageAbstractString(this.conversation.lastMessage);
      const messageCount = `[${this.conversation.unreadCount}${getContext().resourceManager.getStringSync($r('app.string.conversation_list_message_count_unit').id)}] `;
      return messageCount + abstractText;
    }
    return abstract;
  }

  private hasDraft(): boolean {
    return this.conversation.draft !== undefined && this.conversation.draft !== null && this.conversation.draft.length > 0;
  }

  private buildAtTagText(): string {
    if ((this.conversation.unreadCount ?? 0) <= 0 || !this.conversation.conversationID ||
      !this.conversation.conversationID.startsWith('group_')) {
      return '';
    }
    const atInfoList = this.conversation.groupAtInfoList;
    if (!atInfoList || atInfoList.length === 0) {
      return '';
    }
    let hasAtAll = false;
    let hasAtMe = false;
    for (const atInfo of atInfoList) {
      switch (atInfo.atType) {
        case GroupAtType.AT_ALL:
          hasAtAll = true;
          break;
        case GroupAtType.AT_ME:
          hasAtMe = true;
          break;
        case GroupAtType.AT_ALL_AT_ME:
          hasAtAll = true;
          hasAtMe = true;
          break;
      }
    }
    let result = '';
    if (hasAtAll) {
      result += getContext().resourceManager.getStringSync($r('app.string.conversation_at_all_tag').id);
    }
    if (hasAtAll && hasAtMe) {
      result += ' ';
    }
    if (hasAtMe) {
      result += getContext().resourceManager.getStringSync($r('app.string.conversation_at_me_tag').id);
    }
    return result;
  }

  @Builder
  private buildMixedContent() {
    if (typeof this.getDisplaySubTitle() === 'string') {
      if (this.hasDraft()) {
        Text() {
          if (this.conversation.receiveOption !== ReceiveMessageOption.RECEIVE && (this.conversation.unreadCount ?? 0) > 0) {
            Span(`[${this.conversation.unreadCount}${getContext().resourceManager.getStringSync($r('app.string.conversation_list_message_count_unit').id)}]`)
              .fontColor(this.themeState.colors.textColorSecondary)
          }
          if (this.buildAtTagText().length > 0) {
            Span(this.buildAtTagText())
              .fontColor(this.themeState.colors.textColorError)
            Span(' ')
          }
          Span(getContext().resourceManager.getStringSync($r('app.string.conversation_draft_label').id))
            .fontColor(this.themeState.colors.textColorError)
          Span(' ')
          ForEach(EmojiDataManager.parseEmojiText(this.getDisplaySubTitle() as string), (segment: EmojiTextSegment, index: number) => {
            if (segment.type === 'text') {
              Span(segment.content)
                .fontColor(this.themeState.colors.textColorSecondary)
            } else if (segment.type === 'emoji' && segment.imageFile) {
              ImageSpan(EmojiDataManager.getEmojiImageResource(segment.imageFile))
                .width(16)
                .height(16)
                .objectFit(ImageFit.Contain)
                .verticalAlign(ImageSpanAlignment.CENTER)
            }
          }, (segment: EmojiTextSegment, index: number) => `draft_${segment.type}_${index}_${segment.content}`)
        }
        .fontSize(12)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
      } else {
        Text() {
          if (this.buildAtTagText().length > 0) {
            Span(this.buildAtTagText())
              .fontColor(this.themeState.colors.textColorError)
            Span(' ')
          }
          ForEach(EmojiDataManager.parseEmojiText(this.getDisplaySubTitle() as string), (segment: EmojiTextSegment, index: number) => {
            if (segment.type === 'text') {
              Span(segment.content)
            } else if (segment.type === 'emoji' && segment.imageFile) {
              ImageSpan(EmojiDataManager.getEmojiImageResource(segment.imageFile))
                .width(16)
                .height(16)
                .objectFit(ImageFit.Contain)
                .verticalAlign(ImageSpanAlignment.CENTER)
            }
          }, (segment: EmojiTextSegment, index: number) => `${segment.type}_${index}_${segment.content}`)
        }
        .fontSize(12)
        .fontColor(this.themeState.colors.textColorSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
      }
    } else {
      Text() {
        if (this.buildAtTagText().length > 0) {
          Span(this.buildAtTagText())
            .fontColor(this.themeState.colors.textColorError)
          Span(' ')
        }
        Span(this.getDisplaySubTitle())
      }
      .fontSize(12)
      .fontColor(this.themeState.colors.textColorSecondary)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
      .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
    }
  }
}

@Component
@Entry
export struct ConversationList {
  private static readonly AVATAR_SIZE: number = 40;
  private static readonly EDIT_ICON_SIZE: number = 24;
  private static readonly DIVIDER_HEIGHT: number = 0.5;
  private static readonly ITEM_HEIGHT: number = 64;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  @State isLoading: boolean = false;
  @State private conversationCount: number = 0;
  customActions?: ConversationCustomAction[] = [];
  config?: ConversationActionConfigProtocol = undefined;
  private conversationListStyle: ConversationActionConfigProtocol = new ChatConversationActionConfig();
  @State private conversationListStore: ConversationListStore = ConversationListStore.create();
  @State private conversationListState: ConversationListState = this.conversationListStore.state;
  onConversationClick?: (item: ConversationInfo) => void;
  @State private menuConversation: ConversationInfo | undefined = undefined;
  @State private menuY: number = 0;
  @State private menuShowBelow: boolean = true;
  @State private overlayHeight: number = 0;
  private stableDataSource: StableConversationListDataSource = new StableConversationListDataSource();
  private syncConversationCount = (): void => {
    this.conversationCount = this.stableDataSource.totalCount();
  };
  private dataChangeListener: DataChangeListener = {
    onDataReloaded: () => this.syncStableDataSource(),
    onDataAdd: (_index: number) => this.syncStableDataSource(),
    onDataMove: (_from: number, _to: number) => this.syncStableDataSource(),
    onDataChange: (_index: number) => this.syncStableDataSource(),
    onDataDelete: (_index: number) => this.syncStableDataSource(),
    onDataAdded: (_index: number) => this.syncStableDataSource(),
    onDataMoved: (_from: number, _to: number) => this.syncStableDataSource(),
    onDataDeleted: (_index: number) => this.syncStableDataSource(),
    onDataChanged: (_index: number) => this.syncStableDataSource(),
    onDatasetChange: (_dataOperations: DataOperation[]) => this.syncStableDataSource()
  };
  private syncStableDataSource = (): void => {
    const coreSource = this.conversationListState.conversationList;
    const coreItems: ConversationInfo[] = [];
    for (let index = 0; index < coreSource.totalCount(); index++) {
      const item = coreSource.getData(index) as ConversationInfo | null;
      if (item) {
        coreItems.push(item);
      }
    }
    this.stableDataSource.syncFromCore(coreItems);
    this.syncConversationCount();
  };

  aboutToAppear() {
    // Initialize style
    if (this.config) {
      this.conversationListStyle = this.config;
    }

    this.conversationListState.conversationList.registerDataChangeListener(this.dataChangeListener);
    this.syncStableDataSource();

    this.fetchConversationList();
    console.info('ConversationListPage aboutToAppear');
  }

  aboutToDisappear() {
    this.conversationListState.conversationList.unregisterDataChangeListener(this.dataChangeListener);
  }

  @Builder
  EmptyStateBuilder() {
    Column() {
      Image($rawfile('search/empty_chat_icon.svg'))
        .width(100)
        .height(100)
        .fillColor(this.themeState.colors.textColorPrimary)
        .margin({ bottom: 16 })

      Text($r('app.string.no_messages_title'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorTertiary)

      Text($r('app.string.no_messages_desc'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorPrimary)
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  BottomLogoBuilder() {
    Row() {
      Column() {
        Image($rawfile('conversationlist/conversation_bottom_tencent_logo.svg'))
          .width(120)
          .height(20)
          .objectFit(ImageFit.Contain)
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  LoadingStateBuilder() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(this.themeState.colors.textColorPrimary)

      Text($r('app.string.loading_message'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorTertiary)
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ConversationListBuilder() {
    Stack() {
      List({ space: 0 }) {

        LazyForEach(this.stableDataSource, (item: ConversationInfo) => {
          ListItem() {
            ConversationListRow({
              conversation: item,
              isHighlighted: this.menuConversation?.conversationID === item.conversationID,
              onLongPress: (conversation: ConversationInfo, _x: number, rowGlobalY: number) => {
                this.openMenu(conversation, rowGlobalY);
              },
              onConversationClick: (conversation: ConversationInfo) => {
                this.onConversationClick?.(conversation);
                console.info(`Navigate to conversation detail with ID: ${conversation.conversationID}`);
              }
            })
          }
        }, (item: ConversationInfo) => item.conversationID)
      }
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .onReachEnd(() => {

        this.loadMoreConversations();
      })
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
    .alignContent(Alignment.TopStart)
  }

  build() {
    Column() {
      if (this.conversationCount > 0) {

        this.ConversationListBuilder()
      } else if (this.isLoading) {

        this.LoadingStateBuilder()
      } else {
        // Empty state
        Column() {
          this.EmptyStateBuilder()
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.overlayHeight = Number(newValue.height);
    })
    .bindContentCover(this.menuConversation !== undefined, this.MenuOverlayBuilder, {
      backgroundColor: Color.Transparent,
      modalTransition: ModalTransition.NONE
    })
  }

  private formatTimeFromTs(timestamp: number): string | Resource {
    const MIN_VALID_TIMESTAMP = 946684800; // 2000-01-01 00:00:00 UTC
    const now = new Date();
    const MAX_VALID_TIMESTAMP = Math.floor(now.getTime() / 1000) + 365 * 24 * 60 * 60;

    if (!timestamp || timestamp < MIN_VALID_TIMESTAMP || timestamp > MAX_VALID_TIMESTAMP) {
      return '';
    }

    const date = new Date(timestamp * 1000);

    const nowYear = now.getFullYear();
    const nowMonth = now.getMonth();
    const nowDay = now.getDate();

    const dateYear = date.getFullYear();
    const dateMonth = date.getMonth();
    const dateDay = date.getDate();

    const getWeekOfMonth = (targetDate: Date): number => {
      const firstDayOfMonth = new Date(targetDate.getFullYear(), targetDate.getMonth(), 1);
      let firstDayOfWeek = firstDayOfMonth.getDay();
      firstDayOfWeek = (firstDayOfWeek + 1) % 7;
      const dayOfMonth = targetDate.getDate();
      return Math.ceil((dayOfMonth + firstDayOfWeek) / 7);
    };

    if (nowYear !== dateYear) {
      return `${dateYear}/${(dateMonth + 1).toString().padStart(2, '0')}/${dateDay.toString().padStart(2, '0')}`;
    }
    if (nowMonth !== dateMonth) {
      return `${(dateMonth + 1).toString().padStart(2, '0')}/${dateDay.toString().padStart(2, '0')}`;
    }
    const nowWeekOfMonth = getWeekOfMonth(now);
    const dateWeekOfMonth = getWeekOfMonth(date);
    if (nowWeekOfMonth !== dateWeekOfMonth) {
      return `${(dateMonth + 1).toString().padStart(2, '0')}/${dateDay.toString().padStart(2, '0')}`;
    }
    if (nowDay !== dateDay) {
      return this.getLocalizedWeekday(date.getDay());
    }
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  private getLocalizedWeekday(dayOfWeek: number): Resource {
    switch (dayOfWeek) {
      case 0:
        return $r('app.string.sunday');
      case 1:
        return $r('app.string.monday');
      case 2:
        return $r('app.string.tuesday');
      case 3:
        return $r('app.string.wednesday');
      case 4:
        return $r('app.string.thursday');
      case 5:
        return $r('app.string.friday');
      case 6:
        return $r('app.string.saturday');
      default:
        return $r('app.string.unknown');
    }
  }

  private fetchConversationList() {
    this.isLoading = true;
    const option = new ConversationLoadOption();
    option.count = 100;


    this.conversationListStore.loadConversations(option, new CompletionHandlerAdapter(() => {
      this.syncConversationCount();
      if (this.conversationCount === 0) {
        setTimeout(() => {
          this.retryFetchConversationList();
        }, 1000);
      } else {
        this.isLoading = false;
      }
    }, () => {
      this.isLoading = false;
    }));
  }

  private retryFetchConversationList() {
    const option = new ConversationLoadOption();
    option.count = 100;


    this.conversationListStore.loadConversations(option, new CompletionHandlerAdapter(() => {
      this.syncConversationCount();
      this.isLoading = false;
    }, () => {
      this.isLoading = false;
    }));
  }

  private loadMoreConversations() {
    if (this.isLoading || !this.conversationListState.hasMoreConversations) {
      return;
    }


    this.isLoading = true;
    this.conversationListStore.loadMoreConversations(new CompletionHandlerAdapter(() => {
      this.syncConversationCount();
      this.isLoading = false;
    }, () => {
      this.isLoading = false;
    }));
  }

  private handleConversationAction(action: DialogAction, conversationId: string, conversation: ConversationInfo) {
    switch (action) {
      case DialogAction.DELETE:
        AlertDialog.show(
          undefined,
          $r('app.string.delete_conversation_confirm'),
          $r('app.string.cancel'),
          $r('app.string.confirm'),
          undefined,
          undefined,
          () => {
            console.log('Deleting conversation:', conversationId);
            this.deleteConversation(conversation);
          },
          this.getUIContext(),
          true
        );
        break;

      case DialogAction.CLEAR:
        console.log('Clearing conversation messages:', conversationId);
        this.conversationListStore.clearConversationMessages(conversationId, new CompletionHandlerAdapter(undefined, (_code: number, desc: string) => {
          console.error('Failed to clear conversation messages:', desc);
        }));
        break;

      case DialogAction.PIN:
        console.log('Toggling conversation pin status:', conversationId);
        this.conversationListStore.pinConversation(conversationId, !conversation.isPinned,
          new CompletionHandlerAdapter(undefined, (_code: number, desc: string) => {
            console.error('Failed to update conversation pin status:', desc);
          }));
        break;

      case DialogAction.MUTE:
        const mute = conversation.receiveOption === ReceiveMessageOption.RECEIVE;
        this.conversationListStore.setReceiveMessageOpt(conversationId,
          mute ? ReceiveMessageOption.NOT_NOTIFY : ReceiveMessageOption.RECEIVE,
          new CompletionHandlerAdapter(undefined, (_code: number, desc: string) => {
            console.error('Failed to update mute status:', desc);
          }));
        break;

      case DialogAction.MARK_UNREAD:
        if (this.hasUnreadStatus(conversation)) {
          this.conversationListStore.clearConversationUnreadCount(conversationId, new CompletionHandlerAdapter(() => {
            this.conversationListStore.markConversation([conversationId], ConversationMarkType.unread, false,
              new CompletionHandlerAdapter(undefined, (_code: number, desc: string) => {
                console.error('Failed to mark as read:', desc);
              }));
          }, (_code: number, desc: string) => {
            console.error('Failed to clear unread count:', desc);
          }));
        } else {
          this.conversationListStore.markConversation([conversationId], ConversationMarkType.unread, true,
            new CompletionHandlerAdapter(undefined, (_code: number, desc: string) => {
              console.error('Failed to mark as unread:', desc);
            }));
        }
        break;

      case DialogAction.HIDE:
        console.log('Hiding conversation:', conversationId);
        break;
    }
  }

  private deleteConversation(conversation: ConversationInfo) {
    this.conversationListStore.deleteConversation(conversation.conversationID, new CompletionHandlerAdapter());
  }

  /**
   * Check if conversation has unread status (real unread count > 0 OR marked as unread)
   */
  private hasUnreadStatus(item: ConversationInfo): boolean {
    return (item.unreadCount ?? 0) > 0 ||
      item.conversationMarkList.some((m: ConversationMarkType) => m.contains(ConversationMarkType.unread));
  }

  private openMenu(conversation: ConversationInfo, rowGlobalY: number): void {
    this.menuConversation = conversation;
    const margin = 4;
    const aboveOverlap = 8;
    const belowOverlap = Math.max(64 * 3 / 5, 24);
    const itemCount = this.getMenuItems().length;
    const popupHeight = itemCount * 44 + (itemCount - 1) * 0.5;
    const belowY = rowGlobalY + 64 - belowOverlap;
    const aboveY = rowGlobalY - popupHeight + aboveOverlap;
    this.menuShowBelow = belowY + popupHeight <= this.overlayHeight - margin || aboveY < margin;
    this.menuY = this.menuShowBelow
      ? Math.min(belowY, this.overlayHeight - popupHeight - margin)
      : Math.max(aboveY, margin);
  }

  private closeMenu(): void {
    this.menuConversation = undefined;
  }

  @Builder
  private MenuOverlayBuilder() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.closeMenu();
        })

      Stack() {
        this.MenuPopupBuilder()
      }
      .position({
        x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? '0%' : '100%',
        y: this.menuY
      })
      .markAnchor({
        x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? -16 : 140 + 16,
        y: 0
      })
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.overlayHeight = Number(newValue.height);
    })
  }

  @Builder
  private MenuPopupBuilder() {
    Column() {
      ForEach(this.getMenuItems(), (item: ConversationMenuActionItem, index: number) => {
        Column() {
          this.MenuItemBuilder(item.text, item.dangerous, () => this.emitMenuItem(item.value))
          if (index < this.getMenuItems().length - 1) {
            this.MenuDividerBuilder()
          }
        }
      }, (item: ConversationMenuActionItem, index: number) => `${item.value}_${index}`)
    }
    .width(140)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius(8)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private MenuItemBuilder(text: string | Resource, dangerous: boolean, onTap: () => void) {
    Text(text)
      .fontSize(16)
      .fontColor(dangerous ? this.themeState.colors.textColorError : this.themeState.colors.textColorPrimary)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .width('100%')
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .onClick(onTap)
  }

  @Builder
  private MenuDividerBuilder() {
    Divider()
      .width('100%')
      .height(0.5)
      .color(this.themeState.colors.strokeColorSecondary)
      .margin({ left: 16, right: 16 })
  }

  private getMenuItems(): ConversationMenuActionItem[] {
    const items: ConversationMenuActionItem[] = [];
    const conversation = this.menuConversation;
    if (!conversation) {
      return items;
    }
    if (this.shouldShowMenuAction(ConversationAction.MARK_UNREAD)) {
      items.push({
        text: this.hasUnreadStatus(conversation) ? $r('app.string.mark_as_read') : $r('app.string.mark_as_unread'),
        dangerous: false,
        value: ConversationDialogAction.MARK_UNREAD
      });
    }
    if (this.shouldShowMenuAction(ConversationAction.MUTE)) {
      items.push({
        text: conversation.receiveOption === ReceiveMessageOption.RECEIVE ? $r('app.string.mute_conversation') : $r('app.string.unmute_conversation'),
        dangerous: false,
        value: ConversationDialogAction.MUTE
      });
    }
    if (this.shouldShowMenuAction(ConversationAction.PIN)) {
      items.push({
        text: conversation.isPinned ? $r('app.string.unpin_conversation') : $r('app.string.pin_conversation'),
        dangerous: false,
        value: ConversationDialogAction.PIN
      });
    }
    if (this.shouldShowMenuAction(ConversationAction.CLEAR_HISTORY)) {
      items.push({
        text: $r('app.string.clear_messages'),
        dangerous: false,
        value: ConversationDialogAction.CLEAR
      });
    }
    if (this.shouldShowMenuAction(ConversationAction.DELETE)) {
      items.push({
        text: $r('app.string.delete_conversation'),
        dangerous: true,
        value: ConversationDialogAction.DELETE
      });
    }
    if (this.customActions) {
      this.customActions.forEach((action: ConversationCustomAction, index: number) => {
        items.push({
          text: action.title,
          dangerous: false,
          value: `custom_${index}`
        });
      });
    }
    return items;
  }

  private shouldShowMenuAction(action: ConversationAction): boolean {
    if (!this.conversationListStyle) {
      return AppBuilderConfig.getInstance().conversationActionList.includes(action);
    }
    switch (action) {
      case ConversationAction.DELETE:
        return this.conversationListStyle.isSupportDelete ??
          AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.DELETE);
      case ConversationAction.MUTE:
        return this.conversationListStyle.isSupportMute ??
          AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.MUTE);
      case ConversationAction.PIN:
        return this.conversationListStyle.isSupportPin ??
          AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.PIN);
      case ConversationAction.MARK_UNREAD:
        return this.conversationListStyle.isSupportMarkUnread ??
          AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.MARK_UNREAD);
      case ConversationAction.CLEAR_HISTORY:
        return this.conversationListStyle.isSupportClearHistory ??
          AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.CLEAR_HISTORY);
      default:
        return false;
    }
  }

  private emitMenuItem(value: string): void {
    const conversation = this.menuConversation;
    this.closeMenu();
    if (value.startsWith('custom_')) {
      const index = parseInt(value.replace('custom_', ''), 10);
      const action = this.customActions?.[index];
      if (action && action.action && conversation) {
        action.action(conversation);
      }
      return;
    }
    if (conversation) {
      this.handleConversationAction(value as ConversationDialogAction, conversation.conversationID, conversation);
    }
  }
}