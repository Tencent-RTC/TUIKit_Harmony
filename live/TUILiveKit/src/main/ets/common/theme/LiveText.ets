import { LiveTheme } from './LiveTheme'

export class LiveText implements AttributeModifier<TextAttribute> {
  role: LiveTheme.TextRole
  tone: LiveTheme.TextTone
  alignment: TextAlign
  emphasized: boolean
  lineHeight: number

  constructor(role: LiveTheme.TextRole, tone: LiveTheme.TextTone = LiveTheme.TextTone.primary,
    alignment: TextAlign = TextAlign.Start, emphasized: boolean = false, lineHeight: number = 0) {
    this.role = role
    this.tone = tone
    this.alignment = alignment
    this.emphasized = emphasized
    this.lineHeight = lineHeight
  }

  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontSize(LiveTheme.Typography.size(this.role))
      .fontWeight(LiveTheme.Typography.weight(this.role, this.emphasized))
      .fontColor(LiveTheme.Color.text(this.tone))
      .textAlign(this.alignment)
    if (this.lineHeight > 0) {
      instance.lineHeight(this.lineHeight)
    }
  }
}
