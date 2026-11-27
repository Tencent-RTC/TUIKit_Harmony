import { LiveKitResources, LiveKitSafeArea } from '../LiveKitResources'
import { LiveKitLog } from '../log/LiveKitLog'
import { LiveTheme, rgba } from '../theme/LiveTheme'
import { BarrageEmoji, BarrageEmojiConverter } from './emoji/BarrageEmojiConverter'
import { BarrageEmojiPanelView } from './emoji/BarrageEmojiPanelView'
import { KeyboardAvoidMode } from '@kit.ArkUI'

enum BarrageInputMode {
  Keyboard,
  Emoji,
}

class BarrageEditorSpan {
  readonly start: number
  readonly end: number
  readonly text: string
  readonly isImage: boolean
  readonly emoji?: BarrageEmoji

  constructor(start: number, end: number, text: string, isImage: boolean, emoji?: BarrageEmoji) {
    this.start = start
    this.end = end
    this.text = text
    this.isImage = isImage
    this.emoji = emoji
  }
}

@Component
export struct BarrageInputView {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop @Watch('onReset') resetToken: number = 0
  @Prop initialEmojiMode: boolean = false
  @Prop @Watch('onModeRequested') modeRequestToken: number = 0
  onSend: (text: string) => void = () => {}
  onDismiss: () => void = () => {}
  onHeightChanged: (height: number, bottomOffset: number) => void = () => {}
  onPresentationChanged: (isPresented: boolean) => void = () => {}
  @StorageProp(LiveKitSafeArea.keyboardKey) @Watch('onKeyboardChanged') private keyboardHeight: number = 0
  @StorageProp(LiveKitSafeArea.bottomKey) private safeBottom: number = 0
  @State private inputMode: BarrageInputMode = BarrageInputMode.Keyboard
  @State private panelHeight: number = 274
  @State private hasContent: boolean = false
  @State private deleteEnabled: boolean = false
  @State private keyboardPlaceholderOpacity: number = 0
  @State private dismissOffset: number = 0
  private editorController: RichEditorController = new RichEditorController()
  private inputBarHeight: number = 0
  private lastKeyboardPanelHeight: number = 274
  private dismissBottomOffset: number = 0
  private dismissalRevision: number = 0
  private isDismissing: boolean = false
  private wasPresented: boolean = false
  private focusTask: number = -1
  private hasRequestedFocus: boolean = false
  private isMounted: boolean = false
  private isApplyingEdit: boolean = false
  private isEditorReady: boolean = false
  private hasEditorFocus: boolean = false
  private awaitingKeyboardHeight: boolean = false
  private hasLoggedEditorReadFailure: boolean = false
  private previousKeyboardAvoidMode?: KeyboardAvoidMode

  aboutToAppear(): void {
    LiveKitSafeArea.observe()
    this.isMounted = true
    this.onPresentedChanged()
  }

  aboutToDisappear(): void {
    this.isMounted = false
    this.dismissalRevision++
    this.cancelFocusRequest()
    this.releaseFocus()
    this.restoreKeyboardBehavior()
    this.isEditorReady = false
    this.hasEditorFocus = false
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .onClick(() => this.dismissWithAnimation())

      Stack() {
        BarrageEmojiPanelView({
          contentHeight: this.panelHeight,
          isDeleteEnabled: this.deleteEnabled,
          isSendEnabled: this.hasContent,
          onSelect: (emoji: BarrageEmoji) => this.insertEmoji(emoji),
          onDelete: () => this.deleteFromInput(),
          onSend: () => this.send(),
        })
          .position({ left: 0, bottom: 0 })
          .enabled(this.isPresented && this.inputMode === BarrageInputMode.Emoji)

        Column()
          .width('100%')
          .height(Math.max(0, this.panelHeight) + this.safeBottom)
          .backgroundColor('#F6F6F8')
          .opacity(this.keyboardPlaceholderOpacity)
          .position({ left: 0, bottom: 0 })
          .hitTestBehavior(this.inputMode === BarrageInputMode.Keyboard ? HitTestMode.Block : HitTestMode.None)
          .onClick(() => {})

        Column() {
          Row() {
            RichEditor({ controller: this.editorController })
              .id('live-barrage-input')
              .layoutWeight(1)
              .constraintSize({ minHeight: 20, maxHeight: 100 })
              .padding({ left: 0, right: 8, top: 6, bottom: 6 })
              .backgroundColor(Color.Transparent)
              .caretColor(LiveTheme.Color.brandBlue)
              .enterKeyType(EnterKeyType.Send)
              .placeholder(LiveKitResources.localizedString('tuilivekit_comment_friendly_placeholder'), {
                fontColor: rgba(0, 0, 0, 0.4),
                font: { size: 14, weight: 400 },
              })
              .onReady(() => {
                this.isEditorReady = true
                this.editorController.setTypingStyle({
                  fontColor: rgba(0, 0, 0, 0.9),
                  fontSize: 14,
                  fontWeight: 400,
                })
                this.hasLoggedEditorReadFailure = false
                this.refreshTextState()
                this.requestInputFocus()
              })
              .onFocus(() => {
                this.hasEditorFocus = true
                if (this.inputMode === BarrageInputMode.Emoji) {
                  this.applyInputMode(BarrageInputMode.Keyboard)
                }
              })
              .onBlur(() => {
                this.hasEditorFocus = false
              })
              .onClick(() => {
                if (this.inputMode === BarrageInputMode.Emoji) {
                  this.applyInputMode(BarrageInputMode.Keyboard)
                }
              })
              .onSubmit((enterKey: EnterKeyType, event: SubmitEvent) => {
                event.keepEditableState()
                this.send()
              })
              .onIMEInputComplete(() => {
                this.refreshTextState()
                this.enforceCharacterLimit()
              })
              .onDidChange((rangeBefore: TextRange, rangeAfter: TextRange) => {
                if (this.isApplyingEdit) {
                  return
                }
                this.refreshTextState()
                this.enforceCharacterLimit(rangeAfter)
              })

            Image(LiveKitResources.image(this.inputMode === BarrageInputMode.Emoji ?
              'livekit_comment_keyboard' : 'livekit_comment_emoji'))
              .width(24)
              .height(24)
              .objectFit(ImageFit.Contain)
              .margin({ left: 8 })
              .onClick(() => this.toggleInputMode())
          }
          .width('100%')
          .constraintSize({ minHeight: 32 })
          .padding({ left: 12, right: 10 })
          .backgroundColor('#F0F0F2')
          .borderRadius(16)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .constraintSize({ minHeight: 52 })
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#F6F6F8')
        .position({ left: 0, bottom: this.inputBarBottomOffset() })
        .onAreaChange((oldValue: Area, newValue: Area) => {
          this.notifyLayout(newValue.height as number)
        })
      }
      .width('100%')
      .height('100%')
      .position({ left: 0, bottom: 0 })
      .translate({ y: this.dismissOffset })
      .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height('100%')
    .visibility(this.isPresented ? Visibility.Visible : Visibility.Hidden)
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.KEYBOARD], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .hitTestBehavior(HitTestMode.None)
  }

  private onPresentedChanged(): void {
    this.onPresentationChanged(this.isPresented)
    if (this.isPresented) {
      const mode = this.initialEmojiMode ? BarrageInputMode.Emoji : BarrageInputMode.Keyboard
      if (!this.wasPresented) {
        this.dismissalRevision++
        this.isDismissing = false
        this.dismissOffset = 0
        this.previousKeyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode()
        this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE)
        if (mode === BarrageInputMode.Keyboard) {
          this.panelHeight = 0
        }
      }
      this.wasPresented = true
      this.applyInputMode(mode, true)
      return
    }
    if (!this.wasPresented) {
      return
    }
    this.dismissalRevision++
    this.isDismissing = false
    this.dismissOffset = 0
    this.wasPresented = false
    this.awaitingKeyboardHeight = false
    this.releaseFocus()
    this.restoreKeyboardBehavior()
    this.inputMode = BarrageInputMode.Keyboard
    this.keyboardPlaceholderOpacity = 1
    this.notifyLayout()
  }

  private onModeRequested(): void {
    if (this.isPresented) {
      this.applyInputMode(this.initialEmojiMode ? BarrageInputMode.Emoji : BarrageInputMode.Keyboard)
    }
  }

  private onKeyboardChanged(): void {
    if (!this.isDismissing && this.inputMode === BarrageInputMode.Keyboard && this.keyboardHeight > 0) {
      this.lastKeyboardPanelHeight = Math.max(0, this.keyboardHeight - this.safeBottom)
      this.panelHeight = this.lastKeyboardPanelHeight
      this.awaitingKeyboardHeight = false
    }
    this.notifyLayout()
  }

  private onReset(): void {
    this.clearEditor()
    this.inputMode = BarrageInputMode.Keyboard
    this.refreshTextState()
  }

  private applyInputMode(mode: BarrageInputMode, force: boolean = false): void {
    if (this.isDismissing || (!force && this.inputMode === mode)) {
      return
    }
    if (force) {
      this.keyboardPlaceholderOpacity = 0
    }
    const wasEmojiMode = this.inputMode === BarrageInputMode.Emoji
    this.awaitingKeyboardHeight = mode === BarrageInputMode.Keyboard && this.panelHeight > 0 &&
      (wasEmojiMode || this.keyboardHeight <= 0)
    this.inputMode = mode
    if (mode === BarrageInputMode.Emoji) {
      if (this.panelHeight <= 0) {
        this.panelHeight = this.lastKeyboardPanelHeight
      }
      this.awaitingKeyboardHeight = false
      this.cancelFocusRequest()
      this.clearInputFocus()
    } else {
      this.requestInputFocus()
    }
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseInOut }, () => {
      this.keyboardPlaceholderOpacity = mode === BarrageInputMode.Keyboard ? 1 : 0
    })
    this.notifyLayout()
  }

  private toggleInputMode(): void {
    if (!this.isPresented) {
      return
    }
    this.applyInputMode(this.inputMode === BarrageInputMode.Emoji ?
      BarrageInputMode.Keyboard : BarrageInputMode.Emoji)
  }

  private requestInputFocus(): void {
    if (!this.isPresented || this.isDismissing || this.inputMode !== BarrageInputMode.Keyboard || !this.isMounted) {
      return
    }
    this.cancelFocusRequest()
    this.hasRequestedFocus = true
    this.focusTask = setTimeout(() => {
      this.focusTask = -1
      if (this.isPresented && this.inputMode === BarrageInputMode.Keyboard && this.isMounted) {
        this.getUIContext().getFocusController().requestFocus('live-barrage-input')
      }
    }, 0)
  }

  private cancelFocusRequest(): void {
    if (this.focusTask >= 0) {
      clearTimeout(this.focusTask)
      this.focusTask = -1
    }
  }

  private clearInputFocus(): void {
    if (this.hasRequestedFocus || this.hasEditorFocus) {
      this.hasRequestedFocus = false
      this.hasEditorFocus = false
      this.getUIContext().getFocusController().clearFocus()
    }
  }

  private releaseFocus(): void {
    this.cancelFocusRequest()
    if (this.hasRequestedFocus || this.hasEditorFocus) {
      this.getUIContext().getFocusController().clearFocus()
    }
    this.hasRequestedFocus = false
    this.hasEditorFocus = false
  }

  private dismissWithAnimation(): void {
    if (!this.isPresented || this.isDismissing) {
      return
    }
    this.dismissBottomOffset = this.inputBarBottomOffset()
    this.isDismissing = true
    const revision = ++this.dismissalRevision
    this.releaseFocus()
    this.getUIContext().animateTo({
      duration: 250,
      curve: Curve.EaseInOut,
      onFinish: () => {
        if (!this.isMounted || !this.isDismissing || revision !== this.dismissalRevision) {
          return
        }
        this.onDismiss()
      },
    }, () => {
      this.dismissOffset = this.dismissBottomOffset + this.inputBarHeight
    })
  }

  private restoreKeyboardBehavior(): void {
    if (this.previousKeyboardAvoidMode !== undefined) {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode)
      this.previousKeyboardAvoidMode = undefined
    }
  }

  private notifyLayout(height: number = this.inputBarHeight): void {
    if (height > 0) {
      this.inputBarHeight = height
    }
    this.onHeightChanged(this.inputBarHeight, this.inputBarBottomOffset())
  }

  private inputBarBottomOffset(): number {
    if (this.isDismissing) {
      return this.dismissBottomOffset
    }
    if (this.inputMode === BarrageInputMode.Emoji) {
      return Math.max(0, this.panelHeight) + this.safeBottom
    }
    if (this.keyboardHeight > 0) {
      return Math.max(this.keyboardHeight, this.safeBottom)
    }
    return this.awaitingKeyboardHeight ? Math.max(0, this.panelHeight) + this.safeBottom : this.safeBottom
  }

  private refreshTextState(): void {
    const text = this.serializedText()
    if (text === undefined) {
      return
    }
    this.hasContent = text.trim().length > 0
    this.deleteEnabled = text.length > 0
  }

  private serializedText(): string | undefined {
    const spans = this.normalizedSpans(0, -1)
    return spans === undefined ? undefined : this.serializeSpans(spans)
  }

  private serializedRange(start: number, end: number): string | undefined {
    if (end <= start) {
      return ''
    }
    const spans = this.normalizedSpans(start, end)
    return spans === undefined ? undefined : this.serializeSpans(spans)
  }

  private normalizedSpans(start: number, end: number): BarrageEditorSpan[] | undefined {
    if (!this.isEditorReady || !this.isMounted) {
      return undefined
    }
    try {
      const rawSpans = this.editorController.getSpans({ start: start, end: end })
      if (rawSpans === undefined) {
        this.logEditorReadFailure()
        return undefined
      }
      const result: BarrageEditorSpan[] = []
      for (const rawSpan of rawSpans) {
        const textSpan = rawSpan as RichEditorTextSpanResult
        if (textSpan.value !== undefined) {
          const value = textSpan.value
          const offsets = textSpan.offsetInSpan
          const offsetStart = offsets?.[0] ?? 0
          const offsetEnd = offsets?.[1] ?? value.length
          const range = textSpan.spanPosition?.spanRange
          const spanStart = range !== undefined ? range[0] : start - offsetStart
          const spanEnd = range !== undefined ? range[1] : spanStart + value.length
          const effectiveStart = Math.max(start, spanStart + offsetStart)
          const effectiveEnd = end < 0 ? Math.min(spanEnd, spanStart + offsetEnd) :
            Math.min(end, spanEnd, spanStart + offsetEnd)
          if (effectiveEnd <= effectiveStart) {
            continue
          }
          const textOffset = Math.max(0, effectiveStart - spanStart)
          const textEnd = Math.min(value.length, Math.max(textOffset, effectiveEnd - spanStart))
          result.push(new BarrageEditorSpan(effectiveStart, effectiveEnd,
            value.substring(textOffset, textEnd), false))
          continue
        }
        const imageSpan = rawSpan as RichEditorImageSpanResult
        const range = imageSpan.spanPosition?.spanRange
        const spanStart = range !== undefined ? range[0] : start
        const spanEnd = range !== undefined ? range[1] : spanStart + 1
        const effectiveStart = Math.max(start, spanStart)
        const effectiveEnd = end < 0 ? spanEnd : Math.min(end, spanEnd)
        if (effectiveEnd > effectiveStart) {
          const emoji = this.emojiForResource(imageSpan.valueResourceStr)
          if (emoji === undefined) {
            this.logEditorReadFailure()
            return undefined
          }
          result.push(new BarrageEditorSpan(effectiveStart, effectiveEnd, '', true, emoji))
        }
      }
      this.hasLoggedEditorReadFailure = false
      return result
    } catch (error) {
      this.logEditorReadFailure()
      return undefined
    }
  }

  private logEditorReadFailure(): void {
    if (!this.hasLoggedEditorReadFailure) {
      LiveKitLog.warn('[BarrageInputView] RichEditor content is unavailable')
      this.hasLoggedEditorReadFailure = true
    }
  }

  private serializeSpans(spans: BarrageEditorSpan[]): string {
    let result = ''
    for (const span of spans) {
      if (!span.isImage) {
        result += span.text
      } else if (span.emoji !== undefined) {
        result += span.emoji.token
      }
    }
    return result
  }

  private emojiForResource(resource: string | Resource | undefined): BarrageEmoji | undefined {
    if (resource === undefined) {
      return undefined
    }
    const values: string[] = []
    if (typeof resource === 'string') {
      values.push(resource)
    } else {
      const parameters = resource.params as (string | number)[] | undefined
      if (parameters !== undefined) {
        for (const parameter of parameters) {
          if (typeof parameter === 'string') {
            values.push(parameter)
          }
        }
      }
    }
    for (const value of values) {
      const emoji = BarrageEmojiConverter.emojiForAssetName(BarrageEmojiConverter.assetNameFromResource(value))
      if (emoji !== undefined) {
        return emoji
      }
    }
    return undefined
  }

  private insertEmoji(emoji: BarrageEmoji): void {
    if (!this.isPresented || !this.isEditorReady || !this.isMounted) {
      return
    }
    const selection = this.editorController.getSelection()
    if (selection === undefined) {
      return
    }
    const start = selection.selection[0]
    const end = selection.selection[1]
    const currentText = this.serializedText()
    const selectedText = this.serializedRange(start, end)
    if (currentText === undefined || selectedText === undefined) {
      return
    }
    const currentLength = BarrageEmojiConverter.visibleLength(currentText)
    const selectedLength = BarrageEmojiConverter.visibleLength(selectedText)
    if (currentLength - selectedLength >= 200) {
      this.showCharacterLimitToast()
      return
    }
    this.isApplyingEdit = true
    try {
      if (end > start) {
        this.editorController.deleteSpans({ start: start, end: end })
      }
      this.editorController.addImageSpan(LiveKitResources.image(emoji.assetName), {
        offset: start,
        imageStyle: {
          size: [20, 20],
          verticalAlign: ImageSpanAlignment.CENTER,
          objectFit: ImageFit.Contain,
        },
      })
      this.editorController.setCaretOffset(start + 1)
    } finally {
      this.isApplyingEdit = false
    }
    this.refreshTextState()
  }

  private deleteFromInput(): void {
    if (!this.isPresented || !this.isEditorReady || !this.isMounted) {
      return
    }
    const selection = this.editorController.getSelection()
    if (selection === undefined) {
      return
    }
    const start = selection.selection[0]
    const end = selection.selection[1]
    if (start === end && start <= 0) {
      return
    }
    const deleteStart = end > start ? start : this.previousDeleteStart(start)
    if (deleteStart === undefined) {
      return
    }
    this.isApplyingEdit = true
    try {
      this.editorController.deleteSpans({ start: deleteStart, end: end })
      this.editorController.setCaretOffset(deleteStart)
    } finally {
      this.isApplyingEdit = false
    }
    this.refreshTextState()
  }

  private previousDeleteStart(caret: number): number | undefined {
    const spans = this.normalizedSpans(0, caret)
    if (spans === undefined) {
      return undefined
    }
    for (const span of spans) {
      if (caret < span.start || caret > span.end) {
        continue
      }
      if (span.isImage) {
        return span.start
      }
      const prefixLength = Math.min(Math.max(caret - span.start, 0), span.text.length)
      if (prefixLength <= 0) {
        continue
      }
      const characters = BarrageEmojiConverter.characters(span.text.substring(0, prefixLength))
      const last = characters[characters.length - 1]
      if (last !== undefined) {
        return caret - last.length
      }
    }
    return Math.max(0, caret - 1)
  }

  private enforceCharacterLimit(rangeAfter?: TextRange): void {
    if (this.isApplyingEdit) {
      return
    }
    const text = this.serializedText()
    if (text === undefined) {
      return
    }
    const totalLength = BarrageEmojiConverter.visibleLength(text)
    if (totalLength <= 200) {
      return
    }
    const overflow = totalLength - 200
    const start = rangeAfter?.start ?? -1
    const end = rangeAfter?.end ?? -1
    if (start >= 0 && end > start) {
      const changedText = this.serializedRange(start, end)
      if (changedText === undefined) {
        return
      }
      const changedLength = BarrageEmojiConverter.visibleLength(changedText)
      if (changedLength > 0) {
        const removed = Math.min(overflow, changedLength)
        const deleteStart = this.offsetAfterVisibleUnits(start, end, changedLength - removed)
        if (deleteStart === undefined) {
          return
        }
        this.isApplyingEdit = true
        try {
          this.editorController.deleteSpans({ start: deleteStart, end: end })
          this.editorController.setCaretOffset(deleteStart)
        } finally {
          this.isApplyingEdit = false
        }
        this.refreshTextState()
        this.showCharacterLimitToast()
        if (removed < overflow) {
          this.enforceCharacterLimit()
        }
        return
      }
    }
    const spans = this.normalizedSpans(0, -1)
    if (spans === undefined || spans.length === 0) {
      return
    }
    const editorEnd = spans[spans.length - 1].end
    const deleteStart = this.offsetAfterVisibleUnits(0, editorEnd, 200)
    if (deleteStart === undefined) {
      return
    }
    this.isApplyingEdit = true
    try {
      this.editorController.deleteSpans({ start: deleteStart, end: editorEnd })
      this.editorController.setCaretOffset(deleteStart)
    } finally {
      this.isApplyingEdit = false
    }
    this.refreshTextState()
    this.showCharacterLimitToast()
  }

  private offsetAfterVisibleUnits(start: number, end: number, keep: number): number | undefined {
    if (keep <= 0) {
      return start
    }
    let remaining = keep
    const spans = this.normalizedSpans(start, end)
    if (spans === undefined) {
      return undefined
    }
    for (const span of spans) {
      if (!span.isImage) {
        let localOffset = 0
        const segments = BarrageEmojiConverter.parse(span.text)
        for (const segment of segments) {
          if (segment.emoji !== undefined) {
            if (remaining <= 0) {
              return span.start + localOffset
            }
            localOffset += segment.emoji.token.length
            remaining -= 1
          } else {
            const characters = BarrageEmojiConverter.characters(segment.text)
            for (const character of characters) {
              if (remaining <= 0) {
                return span.start + localOffset
              }
              localOffset += character.length
              remaining -= 1
            }
          }
        }
      } else {
        if (remaining <= 0) {
          return span.start
        }
        remaining -= 1
      }
      if (remaining <= 0) {
        return span.end
      }
    }
    return end
  }

  private clearEditor(): void {
    if (!this.isEditorReady || !this.isMounted) {
      return
    }
    this.isApplyingEdit = true
    try {
      this.editorController.deleteSpans()
      this.editorController.setCaretOffset(0)
    } catch (error) {
      this.logEditorReadFailure()
    } finally {
      this.isApplyingEdit = false
    }
    this.refreshTextState()
  }

  private send(): void {
    if (!this.isPresented || !this.isEditorReady || !this.isMounted) {
      return
    }
    const serialized = this.serializedText()
    if (serialized === undefined) {
      return
    }
    const text = serialized.trim()
    if (text.length === 0) {
      this.applyInputMode(BarrageInputMode.Keyboard)
      return
    }
    if (BarrageEmojiConverter.visibleLength(text) > 200) {
      this.enforceCharacterLimit()
      return
    }
    this.onSend(text)
    this.clearEditor()
    this.dismissWithAnimation()
  }

  private showCharacterLimitToast(): void {
    this.getUIContext().getPromptAction().showToast({
      message: LiveKitResources.localizedFormat('tuilivekit_comment_character_limit', 200),
    })
  }
}
