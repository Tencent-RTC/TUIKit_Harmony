import { ThemeState, EventBus } from '../../basecomponent/Index';
import emitter from '@ohos.events.emitter';
import { EmojiItem, EmojiPicker, EmojiDataManager } from '../../emojipicker/Index';
import { MessageInputConfigProtocol, ExpandPanelType } from '../config/MessageInputConfig';
import { MenuItem } from './MessageInputMoreDialog';

/**
 * Callbacks interface for ClassicInputBar
 */
export interface ClassicInputBarCallbacks {
  onSend?: () => void;
  onVoiceRecordStart?: () => void;
  onVoiceRecordEnd?: (cancelled: boolean) => void;
  onVoiceRecordDragUpdate?: (dragOffset: number, shouldCancel: boolean) => void;
  onEmojiSelected?: (emoji: EmojiItem) => void;
  onDeleteClick?: () => void;
  onInputFocusChange?: (focused: boolean) => void;
  onInputChange?: () => void;
  onAtTrigger?: (cursorPosition: number) => void;
  onActionItemClick?: (menuItem: MenuItem) => void;
  onDidChange?: (rangeBefore: TextRange, rangeAfter: TextRange) => boolean;
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
  
  // Internal state
  @State private isVoiceMode: boolean = false; // Voice input mode vs text input mode
  @State private expandPanelType: ExpandPanelType = 'none';
  @State private hasInputContent: boolean = false;
  @State private shouldCancelRecording: boolean = false;
  @State private dragOffset: number = 0;
  
  private hiddenButtonId: string = 'classicHiddenFocusButton';
  private richEditorId: string = 'classic_rich_editor';
  private initialTouchY: number = 0;
  private readonly cancelThreshold: number = -50;
  
  // Classic style dimensions (based on Figma: 750px design width)
  private readonly buttonSize: number = 40; // 56/750 * 375 ≈ 28, but 40 for touch area
  private readonly inputHeight: number = 40;
  private readonly inputBorderRadius: number = 8;
  private readonly panelHeight: number = 280; // Original height for panels
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
              .width(24)
              .height(24)
              .fillColor(this.themeState.colors.textColorSecondary)
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
            .width(24)
            .height(24)
            .fillColor(this.themeState.colors.textColorSecondary)
        }
        .width(this.buttonSize)
        .height(this.buttonSize)
        .backgroundColor(Color.Transparent)
        .borderRadius(this.buttonSize / 2)
        .onClick(() => {
          this.toggleEmojiPanel();
        })

        // Plus button (always shows +, send via keyboard)
        Button() {
          Image($rawfile('messageinput/classic/plus_icon.svg'))
            .width(24)
            .height(24)
            .fillColor(this.themeState.colors.textColorSecondary)
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
      .width('100%')
      .height(56)
      .padding({ left: 12, right: 12 })
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
          minHeight: this.inputHeight,
          maxHeight: 120
        })
        .padding({
          left: 12,
          right: 12,
          top: 8,
          bottom: 8
        })
        .focusable(true)
        .defaultFocus(this.inputFocused && this.expandPanelType === 'none')
        .enterKeyType(EnterKeyType.Send)
        .placeholder($r('app.string.input_message_placeholder'), {
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
        })
        .onBlur(() => {
          console.log('[ClassicInputBar] RichEditor onBlur triggered');
          this.inputFocused = false;
          this.showKeyboardPlaceholder = false;
          if (this.callbacks.onInputFocusChange) {
            this.callbacks.onInputFocusChange(false);
          }
        })
        .onClick(() => {
          console.log('[ClassicInputBar] RichEditor onClick triggered');
          this.inputFocused = true;
          if (this.expandPanelType !== 'none') {
            this.expandPanelType = 'none';
          }
        })
        .onSubmit(() => {
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
        .fontWeight(FontWeight.Medium)
        .fontColor(this.shouldCancelRecording ? 
          '#FF3B30' : 
          this.themeState.colors.textColorPrimary)
    }
    .layoutWeight(1)
    .height(this.inputHeight)
    .backgroundColor(this.isVoiceRecording ? 
      (this.shouldCancelRecording ? '#FFEBEE' : '#E8F5E9') : 
      this.themeState.colors.bgColorInput)
    .borderRadius(this.inputBorderRadius)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        console.log('[ClassicInputBar] Press to speak - touch down');
        this.initialTouchY = event.touches[0].y;
        this.startVoiceRecording();
      } else if (event.type === TouchType.Move) {
        if (this.isVoiceRecording) {
          this.dragOffset = event.touches[0].y - this.initialTouchY;
          this.shouldCancelRecording = this.dragOffset < this.cancelThreshold;
          if (this.callbacks.onVoiceRecordDragUpdate) {
            this.callbacks.onVoiceRecordDragUpdate(this.dragOffset, this.shouldCancelRecording);
          }
        }
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        console.log('[ClassicInputBar] Press to speak - touch up');
        if (this.isVoiceRecording) {
          this.finishVoiceRecording();
        }
      }
    })
    .gesture(
      PanGesture({ fingers: 1, direction: PanDirection.Vertical, distance: 1 })
        .onActionUpdate((event: GestureEvent) => {
          if (this.isVoiceRecording) {
            this.dragOffset = event.offsetY;
            this.shouldCancelRecording = this.dragOffset < this.cancelThreshold;
            if (this.callbacks.onVoiceRecordDragUpdate) {
              this.callbacks.onVoiceRecordDragUpdate(this.dragOffset, this.shouldCancelRecording);
            }
          }
        })
    )
  }

  @Builder
  private buildEmojiPanel() {
    Column() {
      EmojiPicker({
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
    .height(this.panelHeight)
    .backgroundColor(this.themeState.colors.bgColorOperate)
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

  @Builder
  private buildActionPanel() {
    Column() {
      // Swiper for paginated action items
      Swiper() {
        ForEach(this.getActionPages(), (pageItems: MenuItem[], pageIndex: number) => {
          // Each page is a 4x2 grid
          Grid() {
            ForEach(pageItems, (item: MenuItem) => {
              GridItem() {
                Column({ space: 4 }) {
                  Row() {
                    Image(item.icon)
                      .width(21)
                      .height(16)
                  }
                  .width(52)
                  .height(52)
                  .backgroundColor(this.themeState.colors.bgColorInput)
                  .borderRadius(12)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)

                  Text(item.text)
                    .fontSize(11)
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
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .rowsGap(8)
          .columnsGap(8)
          .width('100%')
          .height('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        })
      }
      .indicator(
        new DotIndicator()
          .itemWidth(6)
          .itemHeight(6)
          .selectedItemWidth(6)
          .selectedItemHeight(6)
          .color(this.themeState.colors.strokeColorPrimary)
          .selectedColor(this.themeState.colors.textColorSecondary)
      )
      .loop(false)
      .width('100%')
      .height(this.panelHeight - 20) // Leave space for indicator
    }
    .width('100%')
    .height(this.panelHeight)
    .backgroundColor(this.themeState.colors.bgColorOperate)
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

  // Toggle between voice mode and text mode
  private toggleVoiceMode(): void {
    this.isVoiceMode = !this.isVoiceMode;
    if (this.isVoiceMode) {
      // Switch to voice mode - hide keyboard and panels
      this.hideKeyboard();
      this.expandPanelType = 'none';
    } else {
      // Switch to text mode - focus input
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
    }
  }

  private hideKeyboard(): void {
    this.inputFocused = false;
    this.showKeyboardPlaceholder = false;
    focusControl.requestFocus(this.hiddenButtonId);
  }

  private startVoiceRecording(): void {
    // Don't set isVoiceRecording here - let MessageInput manage it through AudioRecorder callbacks
    this.shouldCancelRecording = false;
    this.dragOffset = 0;
    if (this.callbacks.onVoiceRecordStart) {
      this.callbacks.onVoiceRecordStart();
    }
  }

  private finishVoiceRecording(): void {
    // Only proceed if we're actually recording (managed by MessageInput)
    if (this.isVoiceRecording) {
      const cancelled = this.shouldCancelRecording;
      // Don't set isVoiceRecording here - let MessageInput manage it through AudioRecorder callbacks
      this.shouldCancelRecording = false;
      this.dragOffset = 0;
      if (this.callbacks.onVoiceRecordEnd) {
        this.callbacks.onVoiceRecordEnd(cancelled);
      }
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
