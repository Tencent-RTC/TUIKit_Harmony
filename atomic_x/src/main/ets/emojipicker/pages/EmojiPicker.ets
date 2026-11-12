import { ThemeState } from '../../basecomponent/Index';
import { EmojiDataManager, EmojiItem, EmojiCategory } from '../data/EmojiData';
import { EmojiManager } from '../EmojiManager';
import { Emoji, EmojiGroup } from '../model/EmojiGroup';
import dataPreferences from '@ohos.data.preferences';
import window from '@ohos.window';
@Component
export struct EmojiPicker {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('EmojiGroupState') emojiGroups: EmojiGroup[] = EmojiManager.getInstance().emojiGroupList;
  @State selectedGroupIndex: number = 0;
  @State recentEmojis: EmojiItem[] = [];
  @State bottomSafeHeight: number = 0;
  @State previewEmojiUrl?: ResourceStr = undefined;
  @State previewEmojiId: string = '';
  
  maxRecentEmojis: number = 8;
  panelHeight: number = 280;
  
  onEmojiClick?: (emoji: EmojiItem) => void;

  onCustomEmojiClick?: (group: EmojiGroup, emoji: Emoji) => void;

  onDeleteClick?: () => void;
  
  onSendClick?: () => void;

  aboutToAppear() {
    this.updateBottomSafeHeight();
    this.loadRecentEmojis();
  }

  // Query the system bottom safe-area (navigation indicator) height in vp so the
  // panel can extend below the home indicator to the very bottom of the screen.
  private updateBottomSafeHeight(): void {
    try {
      window.getLastWindow(getContext(this)).then((w: window.Window) => {
        const avoidArea = w.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        const bottomPx = avoidArea.bottomRect.height;
        if (bottomPx > 0) {
          this.bottomSafeHeight = px2vp(bottomPx);
        }
      }).catch(() => {
      });
    } catch (e) {
    }
  }

  build() {
    
    Column() {
      
      if (this.emojiGroups.length > 1) {
        this.buildEmojiGroupTabs()
      }

      
      Stack({ alignContent: Alignment.BottomEnd }) {
        
        this.buildEmojiGrid()

        
        if (this.isLittleEmojiGroup()) {
          this.buildBottomCategoryBar()
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height(this.panelHeight + this.bottomSafeHeight)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius({ topLeft: 12, topRight: 12 })
    .padding({
      top: 12,
      left: 16,
      right: 16,
      bottom: 0
    })
    .transition({
      type: TransitionType.Insert,
      opacity: 1,
      translate: { y: this.panelHeight + this.bottomSafeHeight }
    })
    .transition({
      type: TransitionType.Delete,
      opacity: 0,
      translate: { y: this.panelHeight + this.bottomSafeHeight }
    })
  }

  
  @Builder
  buildEmojiGroupTabs() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.emojiGroups, (group: EmojiGroup, index: number) => {
          Image(group.emojiGroupIconUrl)
            .width(36)
            .height(36)
            .padding(6)
            .objectFit(ImageFit.Contain)
            .borderRadius(4)
            .backgroundColor(index === this.getSelectedGroupIndex() ?
            this.themeState.colors.bgColorBubbleReciprocal : Color.Transparent)
            .onClick(() => {
              this.dismissEmojiPreview();
              this.selectedGroupIndex = index;
            })
        }, (group: EmojiGroup, index: number) => `${index}_${group.id}`)
      }
    }
    .width('100%')
    .height(36)
    .align(Alignment.Start)
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .margin({ bottom: 8 })
  }

  
  @Builder
  buildEmojiGrid() {
    Scroll() {
      Column() {
        
        if (this.isLittleEmojiGroup()) {
          
          if (this.recentEmojis.length > 0) {
            Text(EmojiDataManager.getCategoryDisplayName('recent'))
              .fontSize(14)
              .fontColor(this.themeState.colors.textColorSecondary)
              .fontWeight(FontWeight.Medium)
              .alignSelf(ItemAlign.Start)
              .margin({ top: 8, bottom: 8 })

            Grid() {
              ForEach(this.recentEmojis, (emoji: EmojiItem) => {
                GridItem() {
                  this.buildEmojiItem(emoji, 'recent')
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .rowsGap(8)
            .columnsGap(4)
            .width('100%')
            .margin({ bottom: 16 })
          }

          
          Text(EmojiDataManager.getCategoryDisplayName('all'))
            .fontSize(14)
            .fontColor(this.themeState.colors.textColorSecondary)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          Grid() {
            ForEach(EmojiDataManager.getAllEmojis(), (emoji: EmojiItem) => {
              GridItem() {
                this.buildEmojiItem(emoji, 'all')
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
          .rowsGap(8)
          .columnsGap(4)
          .width('100%')
          .margin({ bottom: 60 }) 
        } else {
          
          Grid() {
            ForEach(this.getSelectedGroupEmojis(), (emoji: Emoji) => {
              GridItem() {
                this.buildCustomEmojiItem(emoji)
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          .rowsGap(8)
          .columnsGap(8)
          .width('100%')
        }
      }
      .width('100%')
      .padding({ top: 4, bottom: 4 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
  }

  
  @Builder
  buildEmojiItem(emoji: EmojiItem, section: string) {
    Column() {
      Image(EmojiDataManager.getEmojiImageResource(emoji.imageFile))
        .width(32)
        .height(32)
        .objectFit(ImageFit.Contain)
        .draggable(false)
    }
    .width(40)
    .height(40)
    .justifyContent(FlexAlign.Center)
    .borderRadius(6)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.selectEmoji(emoji);
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.showEmojiPreview(`${section}_${emoji.id}`, EmojiDataManager.getEmojiImageResource(emoji.imageFile));
        })
    )
    .bindPopup(this.previewEmojiId === `${section}_${emoji.id}`, {
      builder: this.buildEmojiPreview,
      placement: Placement.Top,
      popupColor: this.themeState.colors.bgColorInput,
      enableArrow: true,
      onStateChange: (e) => {
        if (!e.isVisible) {
          this.dismissEmojiPreview();
        }
      }
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        
        this.addPressEffect();
      }
    })
    .stateStyles({
      pressed: {
        .backgroundColor(this.themeState.colors.bgColorInput)
      }
    })
  }

  @Builder
  buildCustomEmojiItem(emoji: Emoji) {
    Column() {
      Image(emoji.emojiUrl)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .draggable(false)
    }
    .width('100%')
    .aspectRatio(1)
    .padding(4)
    .borderRadius(6)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.selectCustomEmoji(emoji);
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.showEmojiPreview(`custom_${emoji.key}`, emoji.emojiUrl);
        })
    )
    .bindPopup(this.previewEmojiId === `custom_${emoji.key}`, {
      builder: this.buildEmojiPreview,
      placement: Placement.Top,
      popupColor: this.themeState.colors.bgColorInput,
      enableArrow: true,
      onStateChange: (e) => {
        if (!e.isVisible) {
          this.dismissEmojiPreview();
        }
      }
    })
    .stateStyles({
      pressed: {
        .backgroundColor(this.themeState.colors.bgColorInput)
      }
    })
  }

  @Builder
  buildEmojiPreview() {
    Image(this.previewEmojiUrl)
      .width(120)
      .height(120)
      .padding(10)
      .objectFit(ImageFit.Contain)
  }

  
  @Builder
  buildBottomCategoryBar() {
    Row() {
      Button() {
        Image($r('sys.media.ohos_ic_back'))
          .width(18)
          .height(18)
          .fillColor(this.themeState.colors.textColorPrimary)
      }
      .width(40)
      .height(30)
      .padding(6)
      .backgroundColor(this.themeState.colors.buttonColorSecondaryDefault)
      .borderRadius(15)
      .margin({ right: 10 })
      .onClick(() => {
        if (this.onDeleteClick) {
          this.onDeleteClick();
        }
      })

      Button($r('app.string.emoji_picker_send'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorButton)
        .backgroundColor(this.themeState.colors.buttonColorPrimaryDefault)
        .borderRadius(15)
        .width(50)
        .height(30)
        .padding(0)
        .onClick(() => {
          if (this.onSendClick) {
            this.onSendClick();
          }
        })
    }
    .alignItems(VerticalAlign.Center)
    .margin({ right: 8 })
    .padding({ top: 16, bottom: this.bottomSafeHeight + 8 })
    .hitTestBehavior(HitTestMode.Transparent)
  }

  
  private getSelectedGroupIndex(): number {
    return Math.min(Math.max(this.selectedGroupIndex, 0), Math.max(this.emojiGroups.length - 1, 0));
  }

  private getSelectedGroup(): EmojiGroup | undefined {
    return this.emojiGroups[this.getSelectedGroupIndex()];
  }

  private getSelectedGroupEmojis(): Emoji[] {
    return this.getSelectedGroup()?.emojis ?? [];
  }

  private isLittleEmojiGroup(): boolean {
    return this.getSelectedGroup()?.isLittleEmoji === true;
  }

  private selectCustomEmoji(emoji: Emoji) {
    const group = this.getSelectedGroup();
    if (group && this.onCustomEmojiClick) {
      this.onCustomEmojiClick(group, emoji);
    }
  }

  private showEmojiPreview(emojiId: string, emojiUrl: ResourceStr) {
    this.previewEmojiUrl = emojiUrl;
    this.previewEmojiId = emojiId;
  }

  private dismissEmojiPreview() {
    this.previewEmojiId = '';
  }

  private selectEmoji(emoji: EmojiItem) {
    

    
    this.addToRecentEmojis(emoji);

    
    if (this.onEmojiClick) {
      this.onEmojiClick(emoji);
    }
  }

  
  private addToRecentEmojis(emoji: EmojiItem) {
    
    this.recentEmojis = this.recentEmojis.filter(item => item.id !== emoji.id);

    
    this.recentEmojis.unshift(emoji);

    
    if (this.recentEmojis.length > this.maxRecentEmojis) {
      this.recentEmojis = this.recentEmojis.slice(0, this.maxRecentEmojis);
    }

    
    this.saveRecentEmojis();
  }

  
  private async loadRecentEmojis() {
    try {
      
      const preferences = await dataPreferences.getPreferences(getContext(this), 'emoji_preferences');
      const recentEmojiIds = await preferences.get('recent_emoji_ids', '[]') as string;

      if (recentEmojiIds && recentEmojiIds !== '[]') {
        const emojiIds: string[] = JSON.parse(recentEmojiIds);
        const loadedEmojis: EmojiItem[] = [];

        
        const limitedIds = emojiIds.slice(0, this.maxRecentEmojis);
        limitedIds.forEach(id => {
          const emoji = EmojiDataManager.getEmojiById(id);
          if (emoji) {
            loadedEmojis.push(emoji);
          }
        });

        this.recentEmojis = loadedEmojis;
        
      } else {
        
        this.recentEmojis = EmojiDataManager.getDefaultRecentEmojis().slice(0, this.maxRecentEmojis);
        
      }
    } catch (error) {
      
      
      this.recentEmojis = EmojiDataManager.getDefaultRecentEmojis().slice(0, this.maxRecentEmojis);
    }
  }

  
  private async saveRecentEmojis() {
    try {
      
      const preferences = await dataPreferences.getPreferences(getContext(this), 'emoji_preferences');
      const emojiIds = this.recentEmojis.map(emoji => emoji.id);
      const emojiIdsJson = JSON.stringify(emojiIds);

      await preferences.put('recent_emoji_ids', emojiIdsJson);
      await preferences.flush();

      
    } catch (error) {
      
    }
  }

  
  private addPressEffect() {
    
    
  }
} 