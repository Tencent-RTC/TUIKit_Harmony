# Base Component - Foundation UI Library

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-API%209+-blue.svg)](https://developer.harmonyos.com/)
[![ArkTS](https://img.shields.io/badge/Language-ArkTS-orange.svg)](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/arkts-get-started-0000001504769321)

Foundation UI components and design system for HarmonyOS applications. Provides reusable, accessible, and theme-aware UI components with consistent design patterns.

## 📚 Table of Contents

- [Overview](#-overview)
- [Design System](#-design-system)
- [Components](#-components)
- [Utilities](#-utilities)
- [Theme Integration](#-theme-integration)
- [Best Practices](#-best-practices)

## 🎯 Overview

Base Component is the foundation layer of the `atomic_x` component library, providing:

- **🎨 Design Tokens**: Colors, Fonts, Spacing, Radius
- **🧩 UI Components**: Button, Avatar, Badge, Label, Switch, Slider
- **📱 Dialogs**: AlertDialog, ActionSheet
- **🛠️ Utilities**: Toast, TextUtils, ImageSizeUtil, Log
- **🌗 Theme System**: Built-in light/dark theme support

## 🎨 Design System

### Colors

Semantic color tokens for consistent theming.

```typescript
import { ThemeState } from '@tencentcloud/atomicx'

@StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance()

// Text Colors
this.themeState.colors.textColorPrimary      // Primary text
this.themeState.colors.textColorSecondary    // Secondary text
this.themeState.colors.textColorTertiary     // Tertiary text
this.themeState.colors.textColorLink         // Links and highlights

// Background Colors
this.themeState.colors.bgColorOperate        // Main background
this.themeState.colors.bgColorInput          // Input background
this.themeState.colors.bgColorSecondary      // Secondary background

// UI Colors
this.themeState.colors.borderColor           // Borders
this.themeState.colors.dividerColor          // Dividers
this.themeState.colors.errorColor            // Error states
this.themeState.colors.successColor          // Success states
```

#### Color Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `textColorPrimary` | #000000 | #FFFFFF | Main text content |
| `textColorSecondary` | #666666 | #AAAAAA | Supporting text |
| `textColorLink` | #1C66E5 | #4A8EFF | Links, highlights |
| `bgColorOperate` | #FFFFFF | #1C1C1E | Main background |
| `bgColorInput` | #F5F5F5 | #2C2C2E | Input fields |
| `errorColor` | #FF3B30 | #FF453A | Error states |
| `successColor` | #34C759 | #32D74B | Success states |

### Fonts

Typography system with consistent font sizes and weights.

```typescript
import { Fonts } from '@tencentcloud/atomicx'

// Font Sizes
Fonts.size.xs    // 12fp
Fonts.size.s     // 14fp
Fonts.size.m     // 16fp
Fonts.size.l     // 18fp
Fonts.size.xl    // 20fp
Fonts.size.xxl   // 24fp

// Font Weights
Fonts.weight.regular   // 400
Fonts.weight.medium    // 500
Fonts.weight.semibold  // 600
Fonts.weight.bold      // 700

// Usage Example
Text('Hello World')
  .fontSize(Fonts.size.m)
  .fontWeight(Fonts.weight.medium)
```

### Spacing

Consistent spacing scale for layouts.

```typescript
import { Spacing } from '@tencentcloud/atomicx'

Spacing.xs   // 4vp
Spacing.s    // 8vp
Spacing.m    // 16vp
Spacing.l    // 24vp
Spacing.xl   // 32vp
Spacing.xxl  // 48vp

// Usage Example
Column({ space: Spacing.m }) {
  // Content with 16vp spacing
}
.padding({ 
  left: Spacing.l,
  right: Spacing.l 
})
```

### Radius

Border radius tokens for consistent rounded corners.

```typescript
import { Radius } from '@tencentcloud/atomicx'

Radius.xs   // 4vp
Radius.s    // 8vp
Radius.m    // 12vp
Radius.l    // 16vp
Radius.xl   // 24vp
Radius.full // 9999vp (fully rounded)

// Usage Example
Column()
  .borderRadius(Radius.m)
```

## 🧩 Components

### Button

Versatile button component with multiple styles and configurations.

#### Basic Usage

```typescript
import { 
  ButtonControl, 
  ButtonContent, 
  ButtonControlType, 
  ButtonColorType, 
  ButtonSize,
  ButtonIconPosition 
} from '@tencentcloud/atomicx'

// Text Button
ButtonControl({
  content: {
    type: ButtonContent.textOnly,
    text: 'Confirm'
  },
  ButtonControlType: ButtonControlType.filled,
  colorType: ButtonColorType.primary,
  buttonSize: ButtonSize.m,
  onButtonClick: () => {
    console.log('Button clicked')
  }
})

// Icon + Text Button
ButtonControl({
  content: {
    type: ButtonContent.iconWithText,
    text: 'Send',
    icon: $r('app.media.icon_send'),
    iconPosition: ButtonIconPosition.start
  },
  ButtonControlType: ButtonControlType.outlined,
  colorType: ButtonColorType.secondary,
  buttonSize: ButtonSize.l,
  onButtonClick: () => {
    console.log('Send clicked')
  }
})

// Icon-Only Button
ButtonControl({
  content: {
    type: ButtonContent.iconOnly,
    icon: $r('app.media.icon_settings')
  },
  ButtonControlType: ButtonControlType.noBorder,
  colorType: ButtonColorType.primary,
  buttonSize: ButtonSize.m,
  onButtonClick: () => {
    console.log('Settings clicked')
  }
})
```

#### API Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `content` | ButtonContentParams | - | Button content configuration |
| `ButtonControlType` | ButtonControlType | filled | Button style (filled/outlined/noBorder) |
| `colorType` | ButtonColorType | primary | Color theme (primary/secondary/danger) |
| `buttonSize` | ButtonSize | m | Button size (xs/s/m/l) |
| `isEnabled` | boolean | true | Enable/disable state |
| `onButtonClick` | () => void | - | Click callback |

#### Button Types

```typescript
enum ButtonControlType {
  filled,    // Solid background
  outlined,  // Border only
  noBorder   // Text only
}

enum ButtonColorType {
  primary,   // Brand color
  secondary, // Gray
  danger     // Red (destructive)
}

enum ButtonSize {
  xs,  // Extra small (24vp height)
  s,   // Small (32vp height)
  m,   // Medium (40vp height)
  l    // Large (48vp height)
}
```

### Avatar

Flexible avatar component supporting images, text fallback, and various shapes.

#### Basic Usage

```typescript
import { Avatar, AvatarSize, AvatarShape, AvatarContentType } from '@tencentcloud/atomicx'

// Image Avatar
Avatar({
  url: 'https://example.com/avatar.jpg',
  name: 'John Doe',
  size: AvatarSize.m,
  shape: AvatarShape.round
})

// Text Fallback Avatar
Avatar({
  name: 'Jane Smith',
  size: AvatarSize.l,
  shape: AvatarShape.roundedRectangle,
  contentType: AvatarContentType.text
})

// With Click Handler
Avatar({
  url: 'https://example.com/avatar.jpg',
  name: 'User',
  size: AvatarSize.m,
  onClick: () => {
    console.log('Avatar clicked')
  }
})
```

#### API Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | string | - | Avatar image URL |
| `name` | string | - | Display name (fallback) |
| `size` | AvatarSize | m | Avatar size |
| `shape` | AvatarShape | round | Avatar shape |
| `contentType` | AvatarContentType | image | Content type |
| `onClick` | () => void | - | Click callback |

#### Avatar Sizes

```typescript
enum AvatarSize {
  xs,  // 24vp
  s,   // 32vp
  m,   // 40vp
  l,   // 48vp
  xl   // 64vp
}
```

### Badge

Badge component for displaying counts or status indicators.

#### Basic Usage

```typescript
import { BadgeControl, BadgeType } from '@tencentcloud/atomicx'

// Text Badge (with count)
BadgeControl({
  type: BadgeType.Text,
  text: '99+'
})

// Dot Badge (indicator only)
BadgeControl({
  type: BadgeType.Dot
})

// Usage with Other Components
Stack() {
  Image($r('app.media.icon_message'))
    .width(24)
    .height(24)
  
  BadgeControl({
    type: BadgeType.Text,
    text: '5'
  })
  .position({ x: 16, y: 0 })
}
```

#### API Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `type` | BadgeType | - | Badge type (Text/Dot) |
| `text` | string | - | Badge text (for Text type) |

### Label (Tag)

Tag/Label component with multiple color variants.

#### Basic Usage

```typescript
import { TagLabel, TagLabelColor, LabelSize } from '@tencentcloud/atomicx'

// Success Label
TagLabel({
  text: 'Success',
  colorType: TagLabelColor.green,
  size: LabelSize.m
})

// Warning Label
TagLabel({
  text: 'Warning',
  colorType: TagLabelColor.orange,
  size: LabelSize.m
})

// Error Label
TagLabel({
  text: 'Error',
  colorType: TagLabelColor.red,
  size: LabelSize.m
})

// Info Label
TagLabel({
  text: 'Info',
  colorType: TagLabelColor.blue,
  size: LabelSize.m
})
```

#### API Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | string | - | Label text |
| `colorType` | TagLabelColor | - | Color variant |
| `size` | LabelSize | m | Label size |

### Switch

Toggle switch component with multiple styles.

#### Basic Usage

```typescript
import { SwitchView, SwitchType } from '@tencentcloud/atomicx'

@State isSwitchOn: boolean = false

SwitchView({
  checked: this.isSwitchOn,
  type: SwitchType.Basic,
  onCheckedChange: (checked: boolean) => {
    this.isSwitchOn = checked
    console.log('Switch state:', checked)
  }
})
```

#### API Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `checked` | boolean | false | Switch state |
| `type` | SwitchType | Basic | Switch type |
| `onCheckedChange` | (checked: boolean) => void | - | Change callback |

### Slider

Slider component with horizontal and vertical orientations.

#### Basic Usage

```typescript
import { SliderControl, SliderOrientation } from '@tencentcloud/atomicx'

@State sliderValue: number = 50

// Horizontal Slider
SliderControl({
  value: this.sliderValue,
  orientation: SliderOrientation.Horizontal,
  valueRange: [0, 100],
  onValueChange: (value: number) => {
    this.sliderValue = Math.round(value)
  }
})
.width('100%')

// Vertical Slider
SliderControl({
  value: this.sliderValue,
  orientation: SliderOrientation.Vertical,
  valueRange: [0, 100],
  onValueChange: (value: number) => {
    this.sliderValue = Math.round(value)
  }
})
.height(120)
.width(48)
```

#### API Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `value` | number | 0 | Current value |
| `orientation` | SliderOrientation | Horizontal | Orientation |
| `enabled` | boolean | true | Enable state |
| `valueRange` | [number, number] | [0, 100] | Value range |
| `showTooltip` | boolean | false | Show tooltip |
| `onValueChange` | (value: number) => void | - | Change callback |

### ActionSheet

Bottom sheet with action items.

#### Basic Usage

```typescript
import { ActionSheet, ActionItem } from '@tencentcloud/atomicx'

const actions: ActionItem[] = [
  { text: 'Edit', value: 'edit' },
  { text: 'Share', value: 'share' },
  { text: 'Delete', value: 'delete', isDestructive: true }
]

ActionSheet({
  title: 'Select Action',
  options: actions,
  showCancel: true,
  cancelText: 'Cancel',
  onActionSelected: (item: ActionItem) => {
    console.log('Selected:', item.value)
  },
  onDismiss: () => {
    console.log('Dismissed')
  }
})
```

#### API Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | string \| Resource | - | Sheet title |
| `options` | ActionItem[] | [] | Action items |
| `showCancel` | boolean | true | Show cancel button |
| `cancelText` | string \| Resource | 'Cancel' | Cancel button text |
| `onActionSelected` | (item: ActionItem) => void | - | Selection callback |
| `onDismiss` | () => void | - | Dismiss callback |

#### ActionItem Interface

```typescript
interface ActionItem {
  text: string | Resource         // Item text
  value?: string | number         // Item value
  isDestructive?: boolean         // Destructive action (red)
  isEnabled?: boolean             // Enable state
  isSelected?: boolean            // Selected state
}
```

### AlertDialog

Alert and confirmation dialogs.

#### Basic Usage

```typescript
import { AlertDialog } from '@tencentcloud/atomicx'

// Single Button Alert
AlertDialog.show({
  title: 'Notice',
  message: 'This is an important message',
  confirmText: 'OK',
  onConfirm: () => {
    console.log('Confirmed')
  }
}, this.getUIContext())

// Confirmation Dialog
AlertDialog.show({
  title: 'Confirm Delete',
  message: 'Are you sure you want to delete this item?',
  confirmText: 'Delete',
  cancelText: 'Cancel',
  onConfirm: () => {
    console.log('Deleted')
  },
  onCancel: () => {
    console.log('Cancelled')
  }
}, this.getUIContext())
```

#### API Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | string \| Resource | - | Dialog title |
| `message` | string \| Resource | - | Dialog message |
| `confirmText` | string \| Resource | 'OK' | Confirm button text |
| `cancelText` | string \| Resource | - | Cancel button text |
| `onConfirm` | () => void | - | Confirm callback |
| `onCancel` | () => void | - | Cancel callback |

## 🛠️ Utilities

### Toast

Global toast notifications with multiple types.

#### Basic Usage

```typescript
import { Toast, ToastType } from '@tencentcloud/atomicx'

// Different Toast Types
Toast.info('Information message', this.getUIContext())
Toast.success('Operation successful', this.getUIContext())
Toast.warning('Warning message', this.getUIContext())
Toast.error('Error occurred', this.getUIContext())
Toast.loading('Loading...', this.getUIContext())

// Custom Duration
Toast.info('Custom message', this.getUIContext(), 4000)

// Simple Native Toast (no UIContext needed)
Toast.shortToast('Quick message')
Toast.longToast('Longer message')
```

#### API Reference

| Method | Parameters | Description |
|--------|------------|-------------|
| `Toast.info(message, context, duration?)` | message, UIContext, ms | Info toast |
| `Toast.success(message, context, duration?)` | message, UIContext, ms | Success toast |
| `Toast.warning(message, context, duration?)` | message, UIContext, ms | Warning toast |
| `Toast.error(message, context, duration?)` | message, UIContext, ms | Error toast |
| `Toast.loading(message, context, duration?)` | message, UIContext, ms | Loading toast |
| `Toast.shortToast(message, bottom?)` | message, position | Native short toast |
| `Toast.longToast(message, bottom?)` | message, position | Native long toast |
| `Toast.closeDialog()` | - | Close current toast |

### TextUtils

Text processing utilities.

#### Basic Usage

```typescript
import { TextUtils } from '@tencentcloud/atomicx'

// Get first letter/character
const firstLetter = TextUtils.getFirstLetter('John Doe')  // 'J'
const firstChinese = TextUtils.getFirstLetter('张三')      // '张'

// Check if empty
const isEmpty = TextUtils.isEmpty('')              // true
const isNotEmpty = TextUtils.isNotEmpty('hello')   // true

// String validation
if (TextUtils.isNotEmpty(username)) {
  // Process username
}
```

#### API Reference

| Method | Parameters | Return | Description |
|--------|------------|--------|-------------|
| `getFirstLetter(text)` | string | string | Get first character |
| `isEmpty(text)` | string | boolean | Check if empty/null |
| `isNotEmpty(text)` | string | boolean | Check if not empty |

### ImageSizeUtil

Image size calculation utilities.

#### Basic Usage

```typescript
import { ImageSizeUtil } from '@tencentcloud/atomicx'

// Calculate display size for an image
const { width, height } = ImageSizeUtil.calculateImageSize(
  1920,  // Original width
  1080,  // Original height
  300    // Max width
)

console.log(`Display size: ${width}x${height}`)
```

### Log

Logging utility with multiple levels.

#### Basic Usage

```typescript
import { Log } from '@tencentcloud/atomicx'

// Different log levels
Log.d('Tag', 'Debug message')
Log.i('Tag', 'Info message')
Log.w('Tag', 'Warning message')
Log.e('Tag', 'Error message')

// Usage example
Log.i('UserService', 'User logged in successfully')
Log.e('NetworkError', 'Failed to fetch data', error)
```

#### API Reference

| Method | Parameters | Description |
|--------|------------|-------------|
| `Log.d(tag, message)` | string, string | Debug log |
| `Log.i(tag, message)` | string, string | Info log |
| `Log.w(tag, message)` | string, string | Warning log |
| `Log.e(tag, message)` | string, string | Error log |

### AZOrderedList

A-Z ordered list with index bar for contact lists.

#### Basic Usage

```typescript
import { AZOrderedList, AZOrderedListItem } from '@tencentcloud/atomicx'

@State contactItems: AZOrderedListItem<ContactInfo>[] = [
  { key: '1', label: 'Alice', avatarUrl: '...', extraData: contactData },
  { key: '2', label: 'Bob', avatarUrl: '...', extraData: contactData },
  // ...
]

AZOrderedList({
  dataSource: this.contactItems,
  config: { showIndexBar: true },
  onItemClick: (item: AZOrderedListItem<ContactInfo>) => {
    console.log('Clicked:', item.label)
  }
})
```

## 🌗 Theme Integration

### Using ThemeState

All components support theme integration through `ThemeState`.

```typescript
import { ThemeState } from '@tencentcloud/atomicx'

@Component
struct ThemedComponent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance()
  
  build() {
    Column() {
      Text('Hello')
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorPrimary)
        .backgroundColor(this.themeState.colors.bgColorOperate)
    }
  }
}
```

### Theme Colors Reference

```typescript
// Access theme colors
this.themeState.colors.textColorPrimary      // ✅ Theme-aware
this.themeState.colors.textColorSecondary
this.themeState.colors.bgColorOperate
// ... more colors

// ❌ Don't use hardcoded colors
.fontColor('#000000')  // Won't adapt to dark mode
```

### Custom Theme

```typescript
// Switch theme
ThemeState.getInstance().switchTheme('dark')  // or 'light'

// Check current theme
const isDarkMode = ThemeState.getInstance().isDarkMode()
```

## 🎯 Best Practices

### 1. Use Design Tokens ✅

```typescript
// ✅ DO: Use design tokens
Column({ space: Spacing.m })
  .padding({ left: Spacing.l, right: Spacing.l })
  .borderRadius(Radius.m)

// ❌ DON'T: Use magic numbers
Column({ space: 16 })
  .padding({ left: 24, right: 24 })
  .borderRadius(12)
```

### 2. Theme Integration ✅

```typescript
// ✅ DO: Use ThemeState
@StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance()
Text('Hello').fontColor(this.themeState.colors.textColorPrimary)

// ❌ DON'T: Hardcode colors
Text('Hello').fontColor('#000000')
```

### 3. Semantic Components ✅

```typescript
// ✅ DO: Use appropriate button types
ButtonControl({
  content: { type: ButtonContent.textOnly, text: 'Delete' },
  colorType: ButtonColorType.danger  // Semantic color
})

// ❌ DON'T: Use generic styling
Button('Delete').backgroundColor('#FF0000')
```

### 4. Consistent Spacing ✅

```typescript
// ✅ DO: Use spacing tokens
Column({ space: Spacing.m })
  .padding({ top: Spacing.l, bottom: Spacing.l })

// ❌ DON'T: Inconsistent spacing
Column({ space: 15 })
  .padding({ top: 22, bottom: 18 })
```

### 5. Accessibility ✅

```typescript
// ✅ DO: Provide meaningful labels
ButtonControl({
  content: { type: ButtonContent.iconOnly, icon: $r('app.media.icon_close') },
  accessibilityText: 'Close'  // Screen reader support
})

// ✅ DO: Ensure sufficient contrast
// Theme colors are designed for WCAG compliance
```

## 📋 Component Checklist

When using Base Component:

- [ ] Import components from `@tencentcloud/atomicx`
- [ ] Use `ThemeState` for theme-aware colors
- [ ] Apply design tokens (Spacing, Radius, Fonts)
- [ ] Provide UIContext for Toast/Dialog components
- [ ] Test in both light and dark themes
- [ ] Ensure proper callback handling
- [ ] Add accessibility labels for icon-only buttons

## 🔄 Migration Guide

### From Custom Components

```typescript
// Before: Custom button
Button('Submit')
  .backgroundColor('#1C66E5')
  .borderRadius(8)
  .fontSize(16)

// After: ButtonControl
ButtonControl({
  content: { type: ButtonContent.textOnly, text: 'Submit' },
  ButtonControlType: ButtonControlType.filled,
  colorType: ButtonColorType.primary,
  buttonSize: ButtonSize.m
})
```

### From Hardcoded Values

```typescript
// Before: Hardcoded values
Column({ space: 16 })
  .padding({ left: 24, right: 24 })
  .borderRadius(12)

// After: Design tokens
Column({ space: Spacing.m })
  .padding({ left: Spacing.l, right: Spacing.l })
  .borderRadius(Radius.m)
```

## 📚 Complete Example

```typescript
import {
  ButtonControl,
  ButtonContent,
  ButtonControlType,
  ButtonColorType,
  ButtonSize,
  Avatar,
  AvatarSize,
  AvatarShape,
  Badge,
  BadgeType,
  TagLabel,
  TagLabelColor,
  LabelSize,
  Toast,
  ThemeState,
  Spacing,
  Radius
} from '@tencentcloud/atomicx'

@Component
struct UserProfileCard {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance()
  @Prop user: UserInfo
  
  build() {
    Column({ space: Spacing.m }) {
      // Avatar with badge
      Stack() {
        Avatar({
          url: this.user.avatarUrl,
          name: this.user.name,
          size: AvatarSize.xl,
          shape: AvatarShape.round
        })
        
        Badge({
          type: BadgeType.Dot
        })
        .position({ x: 48, y: 0 })
      }
      
      // User info
      Column({ space: Spacing.s }) {
        Row({ space: Spacing.s }) {
          Text(this.user.name)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeState.colors.textColorPrimary)
          
          TagLabel({
            text: 'VIP',
            colorType: TagLabelColor.blue,
            size: LabelSize.s
          })
        }
        
        Text(this.user.bio)
          .fontSize(14)
          .fontColor(this.themeState.colors.textColorSecondary)
      }
      
      // Actions
      Row({ space: Spacing.m }) {
        ButtonControl({
          content: {
            type: ButtonContent.textOnly,
            text: 'Message'
          },
          ButtonControlType: ButtonControlType.filled,
          colorType: ButtonColorType.primary,
          buttonSize: ButtonSize.m,
          onButtonClick: () => {
            Toast.success('Starting chat...', this.getUIContext())
          }
        })
        
        ButtonControl({
          content: {
            type: ButtonContent.textOnly,
            text: 'Call'
          },
          ButtonControlType: ButtonControlType.outlined,
          colorType: ButtonColorType.secondary,
          buttonSize: ButtonSize.m,
          onButtonClick: () => {
            Toast.info('Calling...', this.getUIContext())
          }
        })
      }
    }
    .width('100%')
    .padding(Spacing.l)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius(Radius.m)
  }
}
```

## 📖 Additional Resources

- [atomic_x Component Library](../../README.md)
- [HarmonyOS ArkTS Documentation](https://developer.harmonyos.com/)
- [Design Guidelines](../../../docs/DESIGN.md)

## 📝 Changelog

See [CHANGELOG.md](../../../CHANGELOG.md) for version history and updates.

---

**Built with ❤️ for HarmonyOS by Tencent Cloud IM Team**
