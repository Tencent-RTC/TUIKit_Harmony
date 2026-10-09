import { ThemeState, EventBus } from '../../basecomponent/Index';
import { EmojiItem, EmojiDataManager } from '../../emojipicker/Index';
import { MessageInputConfigProtocol } from '../config/MessageInputConfig';

interface VoiceTouchPoint {
  x: number;
  y: number;
}

/**
 * Callbacks interface for MinimalistInputBar
 */
export interface MinimalistInputBarCallbacks {
  onMoreClick?: () => void;
  onEmojiToggle?: (showEmoji: boolean) => void;
  onVoiceRecordStart?: () => void;
  onVoiceRecordEnd?: (x: number, y: number, forceCancel?: boolean) => void;
  onVoiceRecordPointerUpdate?: (x: number, y: number) => void;
  onCameraClick?: () => void;
  onInputFocusChange?: (focused: boolean) => void;
  onSubmit?: () => void;
  onInputChange?: () => void;
  onAtTrigger?: (cursorPosition: number) => void;
  onDidChange?: (rangeBefore: TextRange, rangeAfter: TextRange) => boolean;
  onIMEInputComplete?: (value: RichEditorTextSpanResult) => void;
  onEmojiSelected?: (emoji: EmojiItem) => void;
  onDeleteClick?: () => void;
}

/**
 * MinimalistInputBar - The default input bar style
 * Layout: [+] [RichEditor + emoji button] [microphone] [camera]
 * 
 * This component handles the UI layout only.
 * Business logic (sending messages, recording, etc.) is handled by the parent MessageInput.
 */
@Component
export struct MinimalistInputBar {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  
  // Required properties from parent
  @Link showEmojiPicker: boolean;
  @Link inputFocused: boolean;
  @Link isVoiceRecording: boolean;
  
  // Configuration
  effectiveConfig: MessageInputConfigProtocol = {};
  
  // RichEditor controller passed from parent
  richEditorController: RichEditorController = new RichEditorController();

  // Set while any more menu entry still carries an unconsumed red dot
  @Prop hasMoreActionRedDot: boolean = false;
  
  // Callbacks
  callbacks: MinimalistInputBarCallbacks = {};
  
  // Internal state
  @State private hasInputContent: boolean = false;
  private hiddenButtonId: string = 'minimalistHiddenFocusButton';
  private richEditorId: string = 'minimalist_rich_editor';
  private longPressTimer?: number;

  aboutToAppear() {
    this.checkInputContent();
  }

  build() {
    Column() {
      // Hidden button for keyboard dismiss
      Button()
        .width(0)
        .height(0)
        .opacity(0)
        .focusable(true)
        .id(this.hiddenButtonId)

      Row() {
        // Show more actions button if enabled
        if (this.effectiveConfig.isShowMore) {
        Stack() {
          Button() {
            Image($rawfile('messageinput/plus_icon.svg'))
              .width(20)
              .height(20)
              .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
          }
          .width(36)
          .height(36)
          .backgroundColor(this.themeState.colors.bgColorOperate)
          .borderRadius(18)
          .onClick(() => {
            this.showEmojiPicker = false;
            this.hideKeyboard();
            if (this.callbacks.onMoreClick) {
              this.callbacks.onMoreClick();
            }
          })

          if (this.hasMoreActionRedDot) {
            Circle()
              .width(8)
              .height(8)
              .fill(this.themeState.colors.textColorError)
              .offset({ x: -4, y: 4 })
              .hitTestBehavior(HitTestMode.None)
          }
        }
        .alignContent(Alignment.TopEnd)
      }

      // Input area with RichEditor and emoji button
      Stack() {
        Row() {
          RichEditor({
            controller: this.richEditorController
          })
            .id(this.richEditorId)
            .backgroundColor(this.themeState.colors.bgColorInput)
            .borderRadius(0)
            .layoutWeight(1)
            .constraintSize({
              minHeight: 36,
              maxHeight: 120
            })
            .padding({
              left: 0,
              right: 8,
              top: 8,
              bottom: 8
            })
            .focusable(true)
            .defaultFocus(this.inputFocused && !this.showEmojiPicker)
            .enterKeyType(EnterKeyType.Send)
            .placeholder(this.inputFocused || this.hasInputContent ? '' : $r('app.string.input_message_placeholder'), {
              fontColor: this.themeState.colors.textColorTertiary,
              font: {
                size: 16,
                weight: FontWeight.Normal,
                family: "HarmonyOS Sans",
                style: FontStyle.Normal
              }
            })
            .onFocus(() => {
              console.log('[MinimalistInputBar] RichEditor onFocus triggered');
              this.inputFocused = true;
              if (this.showEmojiPicker) {
                this.showEmojiPicker = false;
              }
              if (this.callbacks.onInputFocusChange) {
                this.callbacks.onInputFocusChange(true);
              }
              const focusEventData: Record<string, Object> = {};
              focusEventData['source'] = 'MinimalistInputBar';
              focusEventData['event'] = 'onInputFocus';
              EventBus.getInstance().post('onInputFocus', focusEventData);
            })
            .onBlur(() => {
              console.log('[MinimalistInputBar] RichEditor onBlur triggered');
              this.inputFocused = false;
              if (this.callbacks.onInputFocusChange) {
                this.callbacks.onInputFocusChange(false);
              }
            })
            .onClick(() => {
              console.log('[MinimalistInputBar] RichEditor onClick triggered');
              if (this.showEmojiPicker) {
                this.showEmojiPicker = false;
              }
              this.inputFocused = true;
            })
            .onSubmit((enterKey: EnterKeyType, event: SubmitEvent) => {
              try {
                event.keepEditableState();
              } catch (_e) {
              }
              if (this.callbacks.onSubmit) {
                this.callbacks.onSubmit();
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
              
              // Call parent's onIMEInputComplete callback
              if (this.callbacks.onIMEInputComplete) {
                this.callbacks.onIMEInputComplete(value);
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
                    console.log(`[MinimalistInputBar] 🔍 onDidChange detected insert: "${insertedText}"`);
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

          // Emoji toggle button
          Image(this.showEmojiPicker ? $rawfile('messageinput/keyboard_icon.svg') :
          $rawfile('messageinput/emoji_icon.svg'))
            .width(19)
            .height(19)
            .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
            .onClick(() => {
              if (this.showEmojiPicker) {
                // Switch from emoji picker to keyboard
                this.showEmojiPicker = false;
                this.inputFocused = true;
                // Use setTimeout to ensure state update completes before requesting focus
                setTimeout(() => {
                  focusControl.requestFocus(this.richEditorId);
                }, 50);
              } else {
                // Switch from keyboard to emoji picker
                this.hideKeyboard();
                this.showEmojiPicker = true;
              }
              if (this.callbacks.onEmojiToggle) {
                this.callbacks.onEmojiToggle(this.showEmojiPicker);
              }
            })
        }
        .width('100%')
        .constraintSize({
          minHeight: 36,
          maxHeight: 120
        })
        .backgroundColor(this.themeState.colors.bgColorInput)
        .borderRadius(18)
        .padding({ left: 16, right: 16 })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .constraintSize({
        minHeight: 36,
        maxHeight: 120
      })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .borderRadius(18)
      .padding({ left: 16, right: 16 })

      // Show voice input button if enabled
      if (this.effectiveConfig.isShowAudioRecorder) {
        Button() {
          Image($rawfile('messageinput/microphone_icon.svg'))
            .width(24)
            .height(24)
            .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
        }
        .width(36)
        .height(36)
        .backgroundColor(this.isVoiceRecording ? '#4A90E2' : this.themeState.colors.bgColorOperate)
        .borderRadius(18)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            console.log('[MinimalistInputBar] Touch down - start long press timer');
            this.startLongPressTimer();
          } else if (event.type === TouchType.Move) {
            const point = this.getWindowTouchPoint(event);
            if (this.isVoiceRecording && point) {
              this.callbacks.onVoiceRecordPointerUpdate?.(point.x, point.y);
            }
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            console.log('[MinimalistInputBar] Touch up/cancel');
            this.cancelLongPressTimer();
            const point = this.getWindowTouchPoint(event, true);
            if (this.isVoiceRecording && point) {
              this.callbacks.onVoiceRecordEnd?.(point.x, point.y, event.type === TouchType.Cancel);
            } else if (this.isVoiceRecording && event.type === TouchType.Cancel) {
              this.callbacks.onVoiceRecordEnd?.(0, 0, true);
            }
          }
        })
      }

      // Show camera button if enabled
      if (this.effectiveConfig.isShowPhotoTaker) {
        Button() {
          Image($rawfile('messageinput/camera_icon.svg'))
            .width(24)
            .height(24)
            .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
        }
        .width(36)
        .height(36)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .borderRadius(18)
        .onClick(() => {
          this.showEmojiPicker = false;
          this.hideKeyboard();
          if (this.callbacks.onCameraClick) {
            this.callbacks.onCameraClick();
          }
        })
      }
      }
      .width('100%')
      .constraintSize({
        minHeight: 50,
        maxHeight: 120
      })
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
    }
  }

  private hideKeyboard() {
    this.inputFocused = false;
    focusControl.requestFocus(this.hiddenButtonId);
  }

  private startLongPressTimer(): void {
    this.longPressTimer = setTimeout(() => {
      console.log('[MinimalistInputBar] Long press timer triggered - start recording');
      if (this.callbacks.onVoiceRecordStart) {
        this.callbacks.onVoiceRecordStart();
      }
    }, 300);
  }

  private cancelLongPressTimer(): void {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = undefined;
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
        const imageSpan = span as RichEditorImageSpanResult;
        if (imageSpan.valueResourceStr !== undefined || imageSpan.valuePixelMap !== undefined) {
          hasContent = true;
          break;
        }
      }
    }
    this.hasInputContent = hasContent;
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
      console.error('[MinimalistInputBar] ❌ Error extracting text:', error);
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
    
    console.log(`[MinimalistInputBar] 📋 Detected ${matches.length} emoji pattern(s) in pasted text`);
    
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
        console.log(`[MinimalistInputBar] ✅ Replaced ${segment.content} with emoji image`);
      }
    });
    
    // Move cursor to end of inserted content
    setTimeout(() => {
      this.richEditorController.setCaretOffset(currentOffset);
    }, 50);
    
    return true; // Emoji was detected and replaced
  }
}
