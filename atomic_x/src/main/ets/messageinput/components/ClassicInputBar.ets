import { ThemeState, EventBus } from '../../basecomponent/Index';
import emitter from '@ohos.events.emitter';
import { EmojiItem, EmojiPicker, EmojiDataManager } from '../../emojipicker/Index';
import { MessageInputConfigProtocol, ExpandPanelType } from '../config/MessageInputConfig';
import { MenuItem } from './MessageInputMoreDialog';

interface VoiceTouchPoint {
  x: number;
  y: number;
}

/**
 * Callbacks interface for ClassicInputBar
 */
export interface ClassicInputBarCallbacks {
  onSend?: () => void;
  onVoiceRecordStart?: (fromTextInput?: boolean) => void;
  onVoiceRecordEnd?: (x: number, y: number, forceCancel?: boolean) => void;
  onVoiceRecordPointerUpdate?: (x: number, y: number) => void;
  onEmojiSelected?: (emoji: EmojiItem) => void;
  onDeleteClick?: () => void;
  onInputFocusChange?: (focused: boolean) => void;
  onInputChange?: () => void;
  onAtTrigger?: (cursorPosition: number) => void;
  onActionItemClick?: (menuItem: MenuItem) => void;
  onDidChange?: (rangeBefore: TextRange, rangeAfter: TextRange) => boolean;
  onChatbotStop?: () => void;
}

/**
 * ClassicInputBar - WeChat-style input bar
 * Layout: [voice] [input/press-to-speak] [emoji] [+/send]
 * 
 * Features:
 * - Voice mode toggle: Click voice button to switch between text input and "press to speak"
 * - Emoji panel: Expands below input bar
 * - Action panel: Expands below input bar (image, video, file, etc.)
 * - Dynamic send button: Shows send when there's text, otherwise shows +
 */
@Component
export struct ClassicInputBar {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  
  // State links from parent
  @Link inputFocused: boolean;
  @Link isVoiceRecording: boolean;
  @Link showKeyboardPlaceholder: boolean;
  
  // Configuration
  effectiveConfig: MessageInputConfigProtocol = {};
  
  // RichEditor controller passed from parent
  richEditorController: RichEditorController = new RichEditorController();

  // Callbacks
  callbacks: ClassicInputBarCallbacks = {};
  
  // Action menu items for expand panel
  actionMenuItems: MenuItem[] = [];

  // Chatbot streaming state: replaces the plus button with a stop-answer button
  @Prop isChatbotActive: boolean = false;
  
  // Internal state
  @State private isVoiceMode: boolean = false; // Voice input mode vs text input mode
  @State private expandPanelType: ExpandPanelType = 'none';
  @State private hasInputContent: boolean = false;
  @State private textInputFocusEnabled: boolean = true;
  
  private hiddenButtonId: string = 'classicHiddenFocusButton';
  private richEditorId: string = 'classic_rich_editor';
  private textInputLongPressTimer?: number;
  private isTextInputRecording: boolean = false;
  private suppressNextTextClick: boolean = false;
  private readonly longPressDuration: number = 300;
  
  // Classic style dimensions aligned with the Android message input toolbar.
  private readonly buttonSize: number = 28;
  private readonly inputHeight: number = 32;
  private readonly inputBorderRadius: number = 4;
  private readonly panelHeight: number = 280; // Original height for panels (used by keyboard placeholder)
  private readonly emojiPanelHeight: number = 240; // Height for emoji panel (more compact)
  private readonly actionPanelHeight: number = 240; // Height for action panel (more compact)
  private readonly itemsPerPage: number = 8; // 4 columns x 2 rows

  aboutToAppear() {
    // Check initial input content
    this.checkInputContent();
    
    // Subscribe to blank area click event to dismiss keyboard
    EventBus.getInstance().on('onBlankAreaClick', (eventData: emitter.EventData) => {
      console.log('[ClassicInputBar] 📨 Received onBlankAreaClick event');
      this.dismissAll();
    });
  }

  aboutToDisappear() {
    this.cancelTextInputLongPress();
    // Unsubscribe from EventBus
    EventBus.getInstance().off('onBlankAreaClick');
  }

  build() {
    Column() {
      // Input bar row
      Row({ space: 8 }) {
        // Voice/Keyboard toggle button
        if (this.effectiveConfig.isShowAudioRecorder) {
          Button() {
            Image(this.isVoiceMode ? 
              $rawfile('messageinput/classic/keyboard_icon.svg') : 
              $rawfile('messageinput/classic/microphone_icon.svg'))
              .width(this.buttonSize)
              .height(this.buttonSize)
          }
          .width(this.buttonSize)
          .height(this.buttonSize)
          .backgroundColor(Color.Transparent)
          .borderRadius(this.buttonSize / 2)
          .onClick(() => {
            this.toggleVoiceMode();
          })
        }

        // Input area - either text input or "press to speak" button
        if (this.isVoiceMode) {
          // "Press to speak" button
          this.buildPressToSpeakButton()
        } else {
          // Text input field
          this.buildTextInput()
        }

        // Emoji button
        Button() {
            Image(this.expandPanelType === 'emoji' ?
              $rawfile('messageinput/classic/keyboard_icon.svg') :
              $rawfile('messageinput/classic/emoji_icon.svg'))
            .width(this.buttonSize)
            .height(this.buttonSize)
        }
        .width(this.buttonSize)
        .height(this.buttonSize)
        .backgroundColor(Color.Transparent)
        .borderRadius(this.buttonSize / 2)
        .onClick(() => {
          this.toggleEmojiPanel();
        })

        // Plus button (always shows +, send via keyboard).
        // Replaced by the stop-answer button while the chatbot is responding.
        if (this.isChatbotActive) {
          Button() {
            Column()
              .width(10)
              .height(10)
              .backgroundColor(this.themeState.colors.textColorButton)
          }
          .width(this.buttonSize)
          .height(this.buttonSize)
          .backgroundColor(this.themeState.colors.buttonColorPrimaryDefault)
          .borderRadius(this.buttonSize / 2)
          .onClick(() => {
            if (this.callbacks.onChatbotStop) {
              this.callbacks.onChatbotStop();
            }
          })
        } else {
          Button() {
            Image($rawfile('messageinput/classic/plus_icon.svg'))
              .width(this.buttonSize)
              .height(this.buttonSize)
          }
          .width(this.buttonSize)
          .height(this.buttonSize)
          .backgroundColor(Color.Transparent)
          .borderRadius(this.buttonSize / 2)
          .onClick(() => {
            // Toggle action panel
            this.toggleActionPanel();
          })
        }
      }
      .width('100%')
      .constraintSize({ minHeight: 56 })
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.themeState.colors.bgColorOperate)

      // Hidden button for keyboard dismiss
      Button()
        .width(0)
        .height(0)
        .opacity(0)
        .focusable(true)
        .id(this.hiddenButtonId)

      // Expand panel area
      if (this.expandPanelType === 'emoji') {
        this.buildEmojiPanel()
      } else if (this.expandPanelType === 'action') {
        this.buildActionPanel()
      }

      // Keyboard placeholder
      if (this.showKeyboardPlaceholder && this.expandPanelType === 'none') {
        Column()
          .width('100%')
          .height(this.panelHeight)
          .backgroundColor('transparent')
          .transition({
            type: TransitionType.Insert,
            opacity: 1,
            translate: { y: 0 }
          })
          .transition({
            type: TransitionType.Delete,
            opacity: 0,
            translate: { y: this.panelHeight }
          })
      }
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  private buildTextInput() {
    Row() {
      RichEditor({
        controller: this.richEditorController
      })
        .id(this.richEditorId)
        .backgroundColor(this.themeState.colors.bgColorInput)
        .borderRadius(this.inputBorderRadius)
        .layoutWeight(1)
        .constraintSize({
          maxHeight: 120
        })
        .padding({
          left: 12,
          right: 12,
          top: 8,
          bottom: 8
        })
        .focusable(this.textInputFocusEnabled && !this.isTextInputRecording)
        .defaultFocus(this.inputFocused && this.expandPanelType === 'none' &&
          this.textInputFocusEnabled && !this.isTextInputRecording)
        .enterKeyType(EnterKeyType.Send)
        .placeholder(this.inputFocused || this.hasInputContent || this.expandPanelType !== 'none'
          ? ''
          : $r('app.string.input_message_placeholder'), {
          fontColor: this.themeState.colors.textColorTertiary,
          font: {
            size: 16,
            weight: FontWeight.Normal,
            family: "HarmonyOS Sans",
            style: FontStyle.Normal
          }
        })
        .onFocus(() => {
          console.log('[ClassicInputBar] RichEditor onFocus triggered');
          if (!this.textInputFocusEnabled || this.isTextInputRecording) {
            this.inputFocused = false;
            this.hideKeyboard();
            return;
          }
          this.inputFocused = true;
          // Close expand panels when focusing on input
          if (this.expandPanelType !== 'none') {
            this.expandPanelType = 'none';
          }
          // Delay showing keyboard placeholder
          setTimeout(() => {
            if (this.inputFocused) {
              this.showKeyboardPlaceholder = true;
            }
          }, 100);
          if (this.callbacks.onInputFocusChange) {
            this.callbacks.onInputFocusChange(true);
          }
          const focusEventData: Record<string, Object> = {};
          focusEventData['source'] = 'ClassicInputBar';
          focusEventData['event'] = 'onInputFocus';
          EventBus.getInstance().post('onInputFocus', focusEventData);
        })
        .onBlur(() => {
          console.log('[ClassicInputBar] RichEditor onBlur triggered');
          this.cancelTextInputLongPress();
          this.inputFocused = false;
          this.showKeyboardPlaceholder = false;
          if (this.callbacks.onInputFocusChange) {
            this.callbacks.onInputFocusChange(false);
          }
        })
        .onClick(() => {
          console.log('[ClassicInputBar] RichEditor onClick triggered');
          if (this.suppressNextTextClick) {
            this.suppressNextTextClick = false;
            this.textInputFocusEnabled = false;
            this.hideKeyboard();
            return;
          }
          this.textInputFocusEnabled = true;
          this.inputFocused = true;
          if (this.expandPanelType !== 'none') {
            this.expandPanelType = 'none';
          }
          setTimeout(() => {
            if (this.inputFocused && this.textInputFocusEnabled && !this.isTextInputRecording) {
              focusControl.requestFocus(this.richEditorId);
            }
          }, 50);
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.scheduleTextInputRecording(event);
          } else if (event.type === TouchType.Move) {
            const point = this.getWindowTouchPoint(event);
            if (this.isTextInputRecording && point) {
              this.callbacks.onVoiceRecordPointerUpdate?.(point.x, point.y);
            }
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.cancelTextInputLongPress();
            if (this.isTextInputRecording) {
              const point = this.getWindowTouchPoint(event, true);
              this.suppressNextTextClick = true;
              this.isTextInputRecording = false;
              this.textInputFocusEnabled = false;
              this.hideKeyboard();
              if (point) {
                this.callbacks.onVoiceRecordEnd?.(point.x, point.y, event.type === TouchType.Cancel);
              } else if (event.type === TouchType.Cancel) {
                this.callbacks.onVoiceRecordEnd?.(0, 0, true);
              }
            }
          }
        })
        .onSubmit((enterKey: EnterKeyType, event: SubmitEvent) => {
          try {
            event.keepEditableState();
          } catch (_e) {
          }
          if (this.callbacks.onSend) {
            this.callbacks.onSend();
          }
        })
        .onIMEInputComplete((value: RichEditorTextSpanResult) => {
          if (value.value && value.value.length > 0) {
            const spanText = value.value;
            const selection = this.richEditorController.getSelection();
            const cursorPos = selection.selection[0];

            // Process input with emoji conversion
            this.processTextInput(spanText, cursorPos, true);
          }
          
          this.checkInputContent();
          if (this.callbacks.onInputChange) {
            this.callbacks.onInputChange();
          }
        })
        .onDidChange((rangeBefore: TextRange, rangeAfter: TextRange) => {
          this.checkInputContent();
          
          // Detect paste via system menu (no onIMEInputComplete triggered)
          if (rangeAfter.end !== undefined && rangeAfter.start !== undefined &&
              rangeBefore.end !== undefined && rangeBefore.start !== undefined) {
            const lengthDiff = rangeAfter.end - rangeAfter.start - (rangeBefore.end - rangeBefore.start);
            if (lengthDiff > 0) {
              // Text was inserted, extract and process it
              const insertedText = this.extractInsertedText(rangeAfter.start, rangeAfter.end);
              if (insertedText.length > 0) {
                console.log(`[ClassicInputBar] 🔍 onDidChange detected insert: "${insertedText}"`);
                // Process only emoji conversion (no @ trigger or style update)
                this.processTextInput(insertedText, rangeAfter.end, false);
              }
            }
          }
          
          // Call parent's onDidChange callback for mention position tracking
          if (this.callbacks.onDidChange) {
            return this.callbacks.onDidChange(rangeBefore, rangeAfter);
          }
          if (this.callbacks.onInputChange) {
            this.callbacks.onInputChange();
          }
          return true;
        })
    }
    .layoutWeight(1)
    .constraintSize({
      minHeight: this.inputHeight,
      maxHeight: 120
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.themeState.colors.bgColorInput)
    .borderRadius(this.inputBorderRadius)
  }

  @Builder
  private buildPressToSpeakButton() {
    Row() {
      Text(this.isVoiceRecording ? 
        $r('app.string.voice_release_to_send') : 
        $r('app.string.voice_press_to_speak'))
        .fontSize(16)
        .fontWeight(FontWeight.Normal)
        .fontColor(this.themeState.colors.textColorPrimary)
    }
    .layoutWeight(1)
    .height(this.inputHeight)
    .backgroundColor(this.isVoiceRecording ? '#E8F5E9' : this.themeState.colors.bgColorInput)
    .borderRadius(this.inputBorderRadius)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        console.log('[ClassicInputBar] Press to speak - touch down');
        this.startVoiceRecording();
      } else if (event.type === TouchType.Move) {
        const point = this.getWindowTouchPoint(event);
        if (this.isVoiceRecording && point) {
          this.callbacks.onVoiceRecordPointerUpdate?.(point.x, point.y);
        }
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        console.log('[ClassicInputBar] Press to speak - touch up');
        const point = this.getWindowTouchPoint(event, true);
        if (this.isVoiceRecording && point) {
          this.callbacks.onVoiceRecordEnd?.(point.x, point.y, event.type === TouchType.Cancel);
        } else if (this.isVoiceRecording && event.type === TouchType.Cancel) {
          this.callbacks.onVoiceRecordEnd?.(0, 0, true);
        }
      }
    })
  }

  @Builder
  private buildEmojiPanel() {
    Column() {
      EmojiPicker({
        showTypeSelector: false,
        panelHeight: this.emojiPanelHeight,
        onEmojiClick: (emoji: EmojiItem) => {
          if (this.callbacks.onEmojiSelected) {
            this.callbacks.onEmojiSelected(emoji);
          }
          this.checkInputContent();
        },
        onDeleteClick: () => {
          if (this.callbacks.onDeleteClick) {
            this.callbacks.onDeleteClick();
          }
          this.checkInputContent();
        },
        onSendClick: () => {
          if (this.callbacks.onSend) {
            this.callbacks.onSend();
          }
        }
      })
    }
    .width('100%')
    .height(this.emojiPanelHeight)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .transition({
      type: TransitionType.Insert,
      opacity: 1,
      translate: { y: 0 }
    })
    .transition({
      type: TransitionType.Delete,
      opacity: 0,
      translate: { y: this.emojiPanelHeight }
    })
  }

  @Builder
  private buildActionPanel() {
    Column() {
      // Swiper for paginated action items
      Swiper() {
        ForEach(this.getActionPages(), (pageItems: MenuItem[], pageIndex: number) => {
          Column() {
            // Each page is a 4x2 grid
            Grid() {
              ForEach(pageItems, (item: MenuItem) => {
                GridItem() {
                  Column({ space: 4 }) {
                    Row() {
                      Image(item.icon)
                        .width(28)
                        .height(28)
                        .fillColor(this.themeState.colors.textColorPrimary)
                    }
                    .width(56)
                    .height(56)
                    .backgroundColor(this.themeState.colors.bgColorInput)
                    .borderRadius(12)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(VerticalAlign.Center)

                    Text(item.text)
                      .fontSize(12)
                      .fontColor(this.themeState.colors.textColorSecondary)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .onClick(() => {
                    if (this.callbacks.onActionItemClick) {
                      this.callbacks.onActionItemClick(item);
                    }
                    // Close panel after action
                    this.expandPanelType = 'none';
                  })
                }
                .height(84)
              })
            }
          .columnsTemplate('1fr 1fr 1fr 1fr')
            .rowsTemplate('auto auto')
            .rowsGap(12)
            .columnsGap(8)
            .width('100%')
            .height(84 * 2 + 12)
            .padding({ left: 12, right: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Start)
          .padding({ top: 24, bottom: 12 })
        })
      }
      .indicator(
        this.getActionPages().length > 1
          ? new DotIndicator()
            .itemWidth(6)
            .itemHeight(6)
            .selectedItemWidth(6)
            .selectedItemHeight(6)
            .color(this.themeState.colors.strokeColorPrimary)
            .selectedColor(this.themeState.colors.textColorSecondary)
          : new DotIndicator()
            .itemWidth(0)
            .itemHeight(0)
            .selectedItemWidth(0)
            .selectedItemHeight(0)
            .color(Color.Transparent)
            .selectedColor(Color.Transparent)
      )
      .loop(false)
      .width('100%')
      .height(this.actionPanelHeight) // Full height so indicator sits at the bottom of the panel
    }
    .width('100%')
    .height(this.actionPanelHeight)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .transition({
      type: TransitionType.Insert,
      opacity: 1,
      translate: { y: 0 }
    })
    .transition({
      type: TransitionType.Delete,
      opacity: 0,
      translate: { y: this.actionPanelHeight }
    })
  }

  // Toggle between voice mode and text mode
  private toggleVoiceMode(): void {
    this.isVoiceMode = !this.isVoiceMode;
    if (this.isVoiceMode) {
      this.hideKeyboard();
      this.expandPanelType = 'none';
    } else {
      this.inputFocused = true;
    }
  }

  // Toggle emoji panel
  private toggleEmojiPanel(): void {
    if (this.expandPanelType === 'emoji') {
      this.expandPanelType = 'none';
      this.inputFocused = true;
      // Use setTimeout to ensure state update completes before requesting focus
      setTimeout(() => {
        focusControl.requestFocus(this.richEditorId);
      }, 50);
    } else {
      this.hideKeyboard();
      this.expandPanelType = 'emoji';
      this.isVoiceMode = false;
      const focusEventData: Record<string, Object> = {};
      focusEventData['source'] = 'ClassicInputBar';
      focusEventData['event'] = 'onInputFocus';
      EventBus.getInstance().post('onInputFocus', focusEventData);
    }
  }

  // Toggle action panel
  private toggleActionPanel(): void {
    if (this.expandPanelType === 'action') {
      this.expandPanelType = 'none';
      this.inputFocused = true;
      // Use setTimeout to ensure state update completes before requesting focus
      setTimeout(() => {
        focusControl.requestFocus(this.richEditorId);
      }, 50);
    } else {
      this.hideKeyboard();
      this.expandPanelType = 'action';
      this.isVoiceMode = false;
      const focusEventData: Record<string, Object> = {};
      focusEventData['source'] = 'ClassicInputBar';
      focusEventData['event'] = 'onInputFocus';
      EventBus.getInstance().post('onInputFocus', focusEventData);
    }
  }

  private hideKeyboard(): void {
    this.inputFocused = false;
    this.showKeyboardPlaceholder = false;
    focusControl.requestFocus(this.hiddenButtonId);
  }

  private scheduleTextInputRecording(event: TouchEvent): void {
    if (this.inputFocused || this.hasInputContent || this.expandPanelType !== 'none' ||
        this.isVoiceMode || this.isVoiceRecording) {
      return;
    }

    this.cancelTextInputLongPress();
    this.textInputLongPressTimer = setTimeout(() => {
      this.textInputLongPressTimer = undefined;
      if (this.inputFocused || this.hasInputContent || this.expandPanelType !== 'none' ||
          this.isVoiceMode || this.isVoiceRecording) {
        return;
      }
      this.suppressNextTextClick = true;
      this.textInputFocusEnabled = false;
      this.hideKeyboard();
      this.isTextInputRecording = true;
      this.showKeyboardPlaceholder = false;
      this.startVoiceRecording(true);
    }, this.longPressDuration);
  }

  private cancelTextInputLongPress(): void {
    if (this.textInputLongPressTimer !== undefined) {
      clearTimeout(this.textInputLongPressTimer);
      this.textInputLongPressTimer = undefined;
    }
  }

  private getWindowTouchPoint(event: TouchEvent, useChangedTouch: boolean = false): VoiceTouchPoint | undefined {
    const touches = useChangedTouch ? event.changedTouches : event.touches;
    const touch = touches?.[0];
    if (!touch) {
      return undefined;
    }
    return {
      x: Number(touch.windowX),
      y: Number(touch.windowY)
    };
  }

  private startVoiceRecording(fromTextInput: boolean = false): void {
    if (this.callbacks.onVoiceRecordStart) {
      this.callbacks.onVoiceRecordStart(fromTextInput);
    }
  }

  // Check if input has content to show send button
  private checkInputContent(): void {
    const spans = this.richEditorController.getSpans({
      start: 0,
      end: -1
    });
    
    let hasContent = false;
    if (spans && spans.length > 0) {
      for (const span of spans) {
        const textSpan = span as RichEditorTextSpanResult;
        if (textSpan.value !== undefined && textSpan.value !== null && textSpan.value.trim().length > 0) {
          hasContent = true;
          break;
        }
        // Image spans (emoji) also count as content
        const imageSpan = span as RichEditorImageSpanResult;
        if (imageSpan.valueResourceStr !== undefined || imageSpan.valuePixelMap !== undefined) {
          hasContent = true;
          break;
        }
      }
    }
    this.hasInputContent = hasContent;
  }

  // Split action menu items into pages (8 items per page)
  private getActionPages(): MenuItem[][] {
    const pages: MenuItem[][] = [];
    for (let i = 0; i < this.actionMenuItems.length; i += this.itemsPerPage) {
      pages.push(this.actionMenuItems.slice(i, i + this.itemsPerPage));
    }
    // Ensure at least one page
    if (pages.length === 0) {
      pages.push([]);
    }
    return pages;
  }

  // Dismiss keyboard and all panels
  private dismissAll(): void {
    console.log('[ClassicInputBar] 🔽 Dismissing keyboard and panels');
    this.hideKeyboard();
    this.expandPanelType = 'none';
    this.isVoiceMode = false;
  }

  // Public method to close panels (called from parent)
  public closePanels(): void {
    this.expandPanelType = 'none';
  }
  
  /**
   * Extract inserted text from RichEditor spans
   * @param start Start position
   * @param end End position
   * @returns Extracted text content
   */
  private extractInsertedText(start: number, end: number): string {
    try {
      const spans = this.richEditorController.getSpans({ start, end });
      let text = '';
      spans.forEach((span: string | RichEditorImageSpanResult | RichEditorTextSpanResult) => {
        if (typeof span === 'string') {
          text += span;
        } else {
          const textSpan = span as RichEditorTextSpanResult;
          if (textSpan.value) {
            text += textSpan.value;
          }
        }
      });
      return text;
    } catch (error) {
      console.error('[ClassicInputBar] ❌ Error extracting text:', error);
      return '';
    }
  }
  
  /**
   * Process text input - handle emoji conversion, text styling, and @ trigger
   * @param text The input text
   * @param cursorPos Cursor position after input
   * @param applyExtraLogic Whether to apply text styling and @ trigger detection (only for IME input)
   */
  private processTextInput(text: string, cursorPos: number, applyExtraLogic: boolean): void {
    // Check if text contains emoji pattern and convert
    const hasEmoji = this.handleEmojiPaste(text, cursorPos);
    
    // Only apply extra logic for IME input (not for system paste)
    if (applyExtraLogic && !hasEmoji) {
      // Apply text style to the span
      this.richEditorController.updateSpanStyle({
        start: cursorPos - text.length,
        end: cursorPos,
        textStyle: {
          fontColor: this.themeState.colors.textColorPrimary
        }
      });

      // Check for "@" trigger
      const lastChar = text[text.length - 1];
      const isAtTrigger: boolean = lastChar === '@' || lastChar === '＠';
      if (isAtTrigger && this.callbacks.onAtTrigger) {
        this.callbacks.onAtTrigger(cursorPos);
      }
    }
  }
  
  /**
   * Handle emoji paste - detect and replace [TUIEmoji_...] patterns with emoji images
   * @param text The pasted text
   * @param cursorPos Current cursor position after paste
   * @returns true if emoji was detected and replaced, false otherwise
   */
  private handleEmojiPaste(text: string, cursorPos: number): boolean {
    // Check if text contains emoji pattern [...]
    const emojiRegex = /\[[a-zA-Z0-9_@\u4e00-\u9fa5]+\]/g;
    const matches = text.match(emojiRegex);
    
    if (!matches || matches.length === 0) {
      return false; // No emoji patterns found
    }
    
    console.log(`[ClassicInputBar] 📋 Detected ${matches.length} emoji pattern(s) in pasted text`);
    
    // Parse the text and get segments (now synchronous)
    const segments = EmojiDataManager.parseEmojiText(text);
    
    // Delete the original text span
    const startPos = cursorPos - text.length;
    this.richEditorController.deleteSpans({
      start: startPos,
      end: cursorPos
    });
    
    // Re-insert content with emojis as images
    let currentOffset = startPos;
    segments.forEach((segment) => {
      if (segment.type === 'text') {
        // Insert plain text
        this.richEditorController.addTextSpan(segment.content, {
          offset: currentOffset,
          style: {
            fontColor: this.themeState.colors.textColorPrimary,
            fontSize: 14
          }
        });
        currentOffset += segment.content.length;
      } else if (segment.type === 'emoji' && segment.imageFile) {
        // Insert emoji as image
        const emojiResource = EmojiDataManager.getEmojiImageResource(segment.imageFile);
        this.richEditorController.addImageSpan(emojiResource, {
          offset: currentOffset,
          imageStyle: {
            size: [20, 20],
            verticalAlign: ImageSpanAlignment.CENTER,
            objectFit: ImageFit.Contain
          }
        });
        currentOffset += 1; // Image span counts as 1 position
        console.log(`[ClassicInputBar] ✅ Replaced ${segment.content} with emoji image`);
      }
    });
    
    // Move cursor to end of inserted content
    setTimeout(() => {
      this.richEditorController.setCaretOffset(currentOffset);
    }, 50);
    
    // Update input content check
    this.checkInputContent();
    
    return true; // Emoji was detected and replaced
  }
}
