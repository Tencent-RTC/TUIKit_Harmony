import { black, LiveTheme, white } from './LiveTheme'

export class LiveSlider implements AttributeModifier<SliderAttribute> {
  applyNormalAttribute(instance: SliderAttribute): void {
    instance.selectedColor(LiveTheme.Color.brandBlue)
      .trackColor(white(0.12))
      .trackThickness(4)
      .blockColor(Color.White)
      .blockBorderColor(LiveTheme.Color.brandBlue)
      .blockBorderWidth(1)
      .blockSize({ width: 16, height: 16 })
      .shadow({ radius: 3, color: black(0.25) })
      .showTips(false)
  }
}
