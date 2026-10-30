import { util } from '@kit.ArkTS'
import { white } from './LiveTheme'

export enum LimitUnit {
  characters,
  utf8Bytes,
}

const encoder: util.TextEncoder = new util.TextEncoder()

export function limitedPrefix(value: string, budget: number, unit: LimitUnit = LimitUnit.characters): string {
  let remaining = Math.max(0, budget)
  let result = ''
  for (const character of Array.from(value)) {
    const length = inputLength(character, unit)
    if (length > remaining) {
      break
    }
    remaining -= length
    result += character
  }
  return result
}

export function inputLength(value: string, unit: LimitUnit = LimitUnit.characters): number {
  return unit === LimitUnit.utf8Bytes ? encoder.encodeInto(value).length : Array.from(value).length
}

// Preserve the unchanged text around an insertion or replacement.
export function limitedEdit(previous: string, value: string, budget: number, unit: LimitUnit): string {
  const before = Array.from(previous)
  const after = Array.from(value)
  let start = 0
  while (start < before.length && start < after.length && before[start] === after[start]) {
    start += 1
  }
  let end = 0
  while (end < before.length - start && end < after.length - start &&
    before[before.length - 1 - end] === after[after.length - 1 - end]) {
    end += 1
  }
  const prefix = after.slice(0, start).join('')
  const suffix = end > 0 ? after.slice(after.length - end).join('') : ''
  const available = Math.max(0, budget - inputLength(prefix + suffix, unit))
  return prefix + limitedPrefix(after.slice(start, after.length - end).join(''), available, unit) + suffix
}

@Component
export struct LiveTextInputView {
  @Link text: string
  @Prop placeholder: string = ''
  @Prop fontSize: number = 14
  @Prop fontWeight: number = 400
  @Prop textAlignment: TextAlign = TextAlign.Start
  inputLimit: number = 0
  limitUnit: LimitUnit = LimitUnit.characters
  maximumLines: number = 1
  minimumHeight: number = 20
  inputID: string = ''
  enterKey: EnterKeyType = EnterKeyType.Done
  onTextChanged?: () => void
  onSubmit?: () => void
  onLimitExceeded?: () => void
  onEditingChanged?: (isEditing: boolean) => void

  aboutToAppear(): void {
    this.text = limitedPrefix(this.text, this.inputLimit, this.limitUnit)
  }

  private willChange(value: EditableTextChangeValue): boolean {
    if (value.previewText !== undefined && value.previewText.value.length > 0) {
      return true
    }
    const next = value.content.endsWith('\n') ? value.content.slice(0, -1) : value.content
    if (inputLength(next, this.limitUnit) <= this.inputLimit) {
      return true
    }
    const accepted = limitedEdit(this.text, next, this.inputLimit, this.limitUnit)
    if (accepted !== this.text) {
      this.text = accepted
      this.onTextChanged?.()
    }
    this.onLimitExceeded?.()
    return false
  }

  private handleChange(value: string, previewText?: PreviewText): void {
    if (previewText !== undefined && previewText.value.length > 0) {
      return
    }
    const shouldSubmit = value.endsWith('\n')
    this.text = shouldSubmit ? value.slice(0, -1) : value
    this.onTextChanged?.()
    if (shouldSubmit) {
      this.onSubmit?.()
    }
  }

  build() {
    TextArea({ text: this.text, placeholder: this.placeholder })
      .id(this.inputID)
      .fontSize(this.fontSize)
      .fontWeight(this.fontWeight)
      .fontColor(Color.White)
      .caretColor(Color.White)
      .placeholderColor(white(0.4))
      .placeholderFont({ size: this.fontSize, weight: this.fontWeight })
      .textAlign(this.textAlignment)
      .backgroundColor(Color.Transparent)
      .padding(0)
      .borderRadius(0)
      .constraintSize({ minHeight: this.minimumHeight, maxHeight: Math.ceil(this.fontSize * 1.4 * this.maximumLines) })
      .wordBreak(WordBreak.BREAK_ALL)
      .enterKeyType(this.enterKey)
      .onSubmit(() => this.onSubmit?.())
      .onWillChange((value: EditableTextChangeValue) => this.willChange(value))
      .onChange((value: string, previewText?: PreviewText) => this.handleChange(value, previewText))
      .onEditChange((isEditing: boolean) => this.onEditingChanged?.(isEditing))
  }
}
