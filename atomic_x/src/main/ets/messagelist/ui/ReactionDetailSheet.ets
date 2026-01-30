import { MessageReaction, UserProfile } from '@tencentcloud/atomicxcore';
import { ThemeState, Avatar, AvatarSize, AvatarContentType } from '../../basecomponent/Index';
import { EmojiDataManager } from '../../emojipicker/data/EmojiData';

@CustomDialog
export struct ReactionDetailSheet {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  controller: CustomDialogController;
  @Prop reactionList: MessageReaction[] = [];
  @Prop currentUserID?: string;
  onFetchUsers?: (reactionID: string) => void;
  onRemoveReaction?: (reactionID: string) => void;
  @State private selectedReactionID: string = '';

  aboutToAppear() {
    if (this.reactionList.length > 0) {
      this.selectedReactionID = this.reactionList[0].reactionID;
      if (this.onFetchUsers) {
        this.onFetchUsers(this.selectedReactionID);
      }
    }
  }

  build() {
    Column() {
      // Drag handle
      Row() {
        Row()
          .width(36)
          .height(4)
          .backgroundColor(this.themeState.colors.strokeColorPrimary)
          .borderRadius(2)
      }
      .width('100%')
      .height(28)
      .justifyContent(FlexAlign.Center)

      // Reaction tabs
      this.ReactionTabRow()

      Divider()
        .height(1)
        .color(this.themeState.colors.strokeColorPrimary)
        .margin({ top: 16 })

      // User list
      this.ReactionUserList()
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 32 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  ReactionTabRow() {
    Scroll() {
      Row() {
        ForEach(this.reactionList, (reaction: MessageReaction) => {
          this.ReactionTab(reaction)
        }, (reaction: MessageReaction) => reaction.reactionID)
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  ReactionTab(reaction: MessageReaction) {
    Row() {
      if (this.getEmoji(reaction)) {
        Image(EmojiDataManager.getEmojiImageResource(this.getEmoji(reaction)!.imageFile))
          .width(18)
          .height(18)
          .objectFit(ImageFit.Contain)
          .margin({ right: 4 })
      }

      Text((reaction.totalUserCount ?? 0).toString())
        .fontSize(14)
        .fontColor(this.isSelected(reaction) ?
          this.themeState.colors.buttonColorPrimaryDefault :
          this.themeState.colors.textColorSecondary)
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(this.isSelected(reaction) ?
      this.themeState.colors.buttonColorPrimaryDefault + '1A' : // 10% opacity
      this.themeState.colors.bgColorInput)
    .borderRadius(16)
    .borderWidth(this.isSelected(reaction) ? 1 : 0)
    .borderColor(this.themeState.colors.buttonColorPrimaryDefault)
    .margin({ right: 8 })
    .onClick(() => {
      this.selectedReactionID = reaction.reactionID;
      if (this.onFetchUsers) {
        this.onFetchUsers(reaction.reactionID);
      }
    })
  }

  @Builder
  ReactionUserList() {
    List() {
      if (this.getSelectedReaction()) {
        ForEach(this.getSortedUsers(this.getSelectedReaction()!), (user: UserProfile) => {
          ListItem() {
            this.UserItem(user, this.isCurrentUser(user, this.getSelectedReaction()!))
          }
        }, (user: UserProfile) => user.userID)
      }
    }
    .width('100%')
    .height(this.getSelectedReaction() ? 300 : 200)
    .margin({ top: 16 })
    .divider({
      strokeWidth: 1,
      color: this.themeState.colors.strokeColorPrimary,
      startMargin: 44,
      endMargin: 0
    })
  }

  @Builder
  UserItem(user: UserProfile, isSelf: boolean) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          name: user.nickname || user.userID || '',
          url: user.avatarURL || ''
        },
        avatarSize: AvatarSize.S
      })

      Column() {
        Text(user.nickname || user.userID || '')
          .fontSize(14)
          .fontWeight(500)
          .fontColor(this.themeState.colors.textColorPrimary)
        
        if (isSelf) {
          Text($r('app.string.messagelist_reaction_tap_to_delete'))
            .fontSize(12)
            .fontColor(this.themeState.colors.textColorTertiary)
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      if (isSelf && this.onRemoveReaction) {
        this.onRemoveReaction(this.selectedReactionID);
        this.controller.close();
      }
    })
  }

  private getSortedUsers(reaction: MessageReaction): UserProfile[] {
    const userList = reaction.partialUserList ?? [];
    const users: UserProfile[] = [];
    
    // Create a copy of the array
    for (let i = 0; i < userList.length; i++) {
      users.push(userList[i]);
    }
    
    // Move current user to front if they reacted
    if ((reaction.reactedByMyself ?? false) && this.currentUserID) {
      const selfIndex = users.findIndex(u => u.userID === this.currentUserID);
      if (selfIndex > 0) {
        const selfUser = users[selfIndex];
        users.splice(selfIndex, 1);
        users.unshift(selfUser);
      }
    }
    
    return users;
  }

  private isCurrentUser(user: UserProfile, reaction: MessageReaction): boolean {
    return user.userID === this.currentUserID && (reaction.reactedByMyself ?? false);
  }

  private getEmoji(reaction: MessageReaction) {
    // reactionID is emoji name like "[TUIEmoji_Smile]"
    const emoji = EmojiDataManager.getEmojiByName(reaction.reactionID);
    if (!emoji) {
      console.warn(`[ReactionDetailSheet] Emoji not found for reactionID: ${reaction.reactionID}`);
    }
    return emoji;
  }

  private isSelected(reaction: MessageReaction): boolean {
    return reaction.reactionID === this.selectedReactionID;
  }

  private getSelectedReaction(): MessageReaction | undefined {
    return this.reactionList.find(r => r.reactionID === this.selectedReactionID);
  }
}
