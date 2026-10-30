export function rgba(red: number, green: number, blue: number, alpha: number = 1): string {
  return `rgba(${Math.round(red * 255)}, ${Math.round(green * 255)}, ${Math.round(blue * 255)}, ${alpha})`
}

export function white(alpha: number): string {
  return `rgba(255, 255, 255, ${alpha})`
}

export function black(alpha: number): string {
  return `rgba(0, 0, 0, ${alpha})`
}

export namespace LiveTheme {
  export enum TextRole {
    sheetTitle,
    dialogTitle,
    pageTitle,
    sectionTitle,
    itemTitle,
    listTitle,
    body,
    prominent,
    caption,
    metadata,
    control,
    action,
  }

  export enum TextTone {
    primary,
    secondary,
    tertiary,
    disabled,
  }

  export class Typography {
    private static readonly sizes: number[] = [15, 16, 21, 12, 13, 15, 14, 17, 12, 10, 11, 13]
    private static readonly semibold: TextRole[] =
      [TextRole.sheetTitle, TextRole.dialogTitle, TextRole.pageTitle, TextRole.sectionTitle, TextRole.prominent, TextRole.action]

    static size(role: TextRole): number {
      return Typography.sizes[role]
    }

    static weight(role: TextRole, emphasized: boolean = false): number {
      return emphasized || Typography.semibold.includes(role) ? 600 : 400
    }
  }

  export class Color {
    static readonly brandBlue: string = rgba(0.29, 0.62, 1)
    static readonly brandDeepBlue: string = rgba(0, 0.32, 0.85)
    static readonly brandCyan: string = rgba(0.49, 0.91, 1)
    static readonly canvasBackground: string = rgba(0.06, 0.07, 0.10)
    static readonly overlayBase: string = rgba(0.039, 0.047, 0.071)
    static readonly controlBase: string = rgba(0.039, 0.039, 0.059)
    static readonly nickname: string = rgba(0.471, 0.847, 1)
    static readonly audienceGiftValue: string = rgba(1, 0.886, 0.604)
    static readonly sheetScrim: string = black(0.4)

    static overlay(alpha: number): string {
      return rgba(0.039, 0.047, 0.071, alpha)
    }

    static control(alpha: number): string {
      return rgba(0.039, 0.039, 0.059, alpha)
    }

    static brand(alpha: number): string {
      return rgba(0.29, 0.62, 1, alpha)
    }

    static text(tone: TextTone): string {
      return [white(1), white(0.75), white(0.48), white(0.38)][tone]
    }
  }
}

export class LiveVideoOverlayStyle {
  static readonly capsuleBackground: string = LiveTheme.Color.overlay(0.22)
}

export class LiveHeaderStyle {
  static readonly middle: string = rgba(0.055, 0.063, 0.11, 0.20)
  static readonly purple: string = rgba(0.482, 0.302, 1, 0.18)
  static readonly rose: string = rgba(1, 0.357, 0.478, 0.16)
  static readonly border: string = white(0.06)
  static readonly capsuleRadius: number = 18
  static readonly avatarRadius: number = 16
}

export class LiveAudienceRowStyle {
  static readonly giftValueFontSize: number = 12
  static readonly separator: string = white(0.08)
  static readonly avatarRadius: number = 21
  static readonly edgeInset: number = 10
  static readonly avatarLeading: number = 36
  static readonly avatarTop: number = 11
  static readonly avatarSize: number = 42
  static readonly nameLeading: number = 92
  static readonly rankWidth: number = 12
  static readonly rankHeight: number = 21
  static readonly giftValueWidth: number = 38
  static readonly giftValueHeight: number = 16
}
