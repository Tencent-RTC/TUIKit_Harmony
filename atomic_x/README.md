# Atomic_X - HarmonyOS IM UIKit Component Library

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-API%209+-blue.svg)](https://developer.harmonyos.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-orange.svg)](./CHANGELOG.md)

A comprehensive, production-ready instant messaging UI component library for HarmonyOS applications. Built with ArkTS, Atomic_X provides enterprise-grade IM features including chat interfaces, contact management, multimedia messaging, and real-time communication capabilities.

## 📚 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Core Components](#-core-components)
- [Configuration System](#-configuration-system)
- [Theme System](#-theme-system)
- [Best Practices](#-best-practices)
- [API Reference](#-api-reference)

## ✨ Features

### 🎯 Core Capabilities
- **Complete IM Solution**: Full-featured instant messaging UI components
- **Message Types**: Text, image, video, audio, file, emoji, and system messages
- **Real-time Updates**: Observable state management with @State/@ObjectLink
- **Multimedia Support**: Built-in media picker, recorder, player, and viewer
- **Contact Management**: Friend lists, group management, blacklist, and applications
- **Conversation Management**: Conversation list with unread counts, pinning, and muting
- **Rich Input**: Message input with emoji picker, @mentions, file attachments
- **Customizable UI**: Flexible styling system with global and local configurations

### 🎨 Design System
- **Unified Theme**: Consistent colors, fonts, spacing, and radius tokens
- **Light/Dark Mode**: Built-in theme support with automatic switching
- **Responsive Design**: Adaptive layouts for different screen sizes
- **Accessibility**: WCAG-compliant with proper contrast ratios

### ⚡ Performance
- **Lazy Loading**: Efficient rendering for large message lists
- **Memory Optimization**: Automatic resource cleanup and recycling
- **State Management**: Centralized store pattern for data consistency
- **Type Safety**: Full ArkTS type definitions throughout

## 🏗 Architecture

```
atomic_x/
├── basecomponent/          # Foundation UI components
│   ├── components/         # Avatar, Button, Badge, Dialog, etc.
│   ├── theme/             # Design tokens (Colors, Fonts, Spacing)
│   └── utils/             # Helper utilities
├── messagelist/           # Message display and management
│   ├── cells/            # Message cell renderers (Text, Image, Video, etc.)
│   ├── components/       # MessageList component
│   ├── config/           # MessageListConfig for styling
│   └── ui/               # MessageItem, MessageActionPanel
├── messageinput/         # Message composition
│   ├── components/       # MessageInput, AudioRecorder
│   └── config/          # MessageInputConfig
├── conversationlist/     # Conversation list
│   ├── pages/           # ConversationList component
│   └── config/          # ConversationListConfig
├── contactlist/          # Contact management
│   ├── pages/           # ContactList and manager views
│   ├── components/      # Contact-related dialogs
│   └── datasource/      # Contact data management
├── chatsetting/          # Chat settings and profiles
│   ├── pages/           # C2C/Group chat settings
│   └── helper/          # User interaction helpers
└── [media components]/   # Image/Video/Audio/File pickers and players
```

### Data Flow Pattern

```typescript
// Centralized Store Management
HomePage (Top Level)
  @State contactListStore: ContactListStore
  @State conversationListStore: ConversationListStore
  
  ↓ Pass down via @ObjectLink
  
ContactsPage/ConversationsPage (Middle Layer)
  @ObjectLink store
  
  ↓ Pass down via @ObjectLink
  
ContactList/ConversationList (UI Components)
  @ObjectLink store
  → Trigger callbacks
  → Update UI reactively
```

## 📦 Installation

### Prerequisites

- **HarmonyOS SDK**: API 9 or higher
- **DevEco Studio**: 4.0 or later
- **Dependencies**: `@tencentcloud/atomicxcore` (included)

### Add Dependency

Add to your `oh-package.json5`:

```json5
{
  "dependencies": {
    "@tencentcloud/atomicx": "^1.0.0",
    "@tencentcloud/atomicxcore": "^1.0.0"
  }
}
```

## 🚀 Quick Start

### 1. Complete Chat Application

```typescript
import { ChatDialog } from '@tencentcloud/atomicx'
import { ConversationInfo } from '@tencentcloud/atomicxcore'

@Entry
@Component
struct HomePage {
  private chatDialogController?: CustomDialogController

  private showChatDialog(conversationID: string, title: string): void {
    this.chatDialogController = new CustomDialogController({
      builder: ChatDialog({
        conversationID: conversationID,
        title: title,
        onBack: () => {
          console.log('Chat closed')
        }
      }),
      alignment: DialogAlignment.Center,
      customStyle: true
    })
    this.chatDialogController.open()
  }

  build() {
    Column() {
      Button('Start Chat')
        .onClick(() => {
          this.showChatDialog('c2c_user123', 'John Doe')
        })
    }
  }
}
```

### 2. Contact List with Store

```typescript
import { ContactList } from '@tencentcloud/atomicx'
import { ContactListStore, ContactInfo } from '@tencentcloud/atomicxcore'

@Component
export struct ContactsPage {
  @State private contactListStore: ContactListStore = ContactListStore.create()

  aboutToAppear() {
    this.contactListStore.fetchFriendList()
    this.contactListStore.fetchFriendApplicationList()
  }

  build() {
    Column() {
      ContactList({
        contactListStore: this.contactListStore,
        onContactClick: (contact: ContactInfo) => {
          console.log('Contact clicked:', contact.contactID)
        },
        onNewFriendsClick: () => {
          // Show new friend applications
        }
      })
    }
  }
}
```

### 3. Conversation List with Callbacks

```typescript
import { ConversationList } from '@tencentcloud/atomicx'
import { ConversationListStore, ConversationInfo } from '@tencentcloud/atomicxcore'

@Component
export struct ConversationsPage {
  @State private conversationListStore: ConversationListStore = 
    ConversationListStore.create()

  build() {
    Column() {
      ConversationList({
        onConversationClick: (item: ConversationInfo) => {
          console.log('Open conversation:', item.ID)
          // Navigate to chat
        }
      })
    }
  }
}
```

## 🎯 Core Components

### 💬 MessageList

Displays chat messages with support for multiple message types and interactions.

```typescript
import { MessageList, ChatMessageListConfig, MessageCustomAction } from '@tencentcloud/atomicx'
import { MessageInfo } from '@tencentcloud/atomicxcore'
import promptAction from '@ohos.promptAction'

MessageList({
  conversationID: 'c2c_user123',
  config: new ChatMessageListConfig({
    isShowAvatar: true,
    isShowLeftAvatar: true,
    isShowRightAvatar: false,
    alignment: MessageAlignment.left,
    horizontalPadding: 16,
    avatarSpacing: 6,
    isShowLeftNickname: true,
    isShowRightNickname: false,
    isShowTimeInBubble: true,
    cellSpacing: 2,
    isSupportCopy: true,
    isSupportDelete: true,
    isSupportRecall: true
  }),
  customActions: [
    {
      title: 'Forward',
      iconName: $rawfile('messagelist/icon_forward.svg'),
      action: (message: MessageInfo) => {
        console.log('Forward message:', message.msgID)
        promptAction.showToast({
          message: `Forward message: ${message.msgID}`,
          duration: 2000
        })
      }
    },
    {
      title: 'Translate',
      iconName: $rawfile('messagelist/icon_translate.svg'),
      action: (message: MessageInfo) => {
        console.log('Translate message:', message.msgID)
        // Implement translation logic
      }
    }
  ],
  onUserClick: (userID: string) => {
    console.log('User clicked:', userID)
  },
  onMessageLongPress: (message: MessageInfo) => {
    console.log('Message long pressed:', message.msgID)
  }
})
```

#### Custom Actions

`MessageList` supports custom actions that appear in the message action menu (shown on long press). Each custom action requires:

- **`title`** (string | Resource): Display text for the action button
- **`iconName`** (string | Resource, optional): Icon resource for the action
- **`action`** ((message: MessageInfo) => void): Callback function executed when action is triggered

Custom actions will be displayed alongside system actions (Copy, Delete, Recall) in the message action panel. The system automatically assigns internal identifiers based on the array index, so you don't need to provide an `id` field.

#### Configuration Options

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `isShowAvatar` | boolean | true | Show/hide avatars |
| `isShowLeftAvatar` | boolean | true | Show avatar for left-aligned messages |
| `isShowRightAvatar` | boolean | false | Show avatar for right-aligned messages |
| `alignment` | MessageAlignment | left | Message alignment (left/right/center) |
| `horizontalPadding` | number | 16 | Horizontal padding (vp) |
| `avatarSpacing` | number | 6 | Space between avatar and message (vp) |
| `isShowLeftNickname` | boolean | false | Show nickname for left messages |
| `isShowRightNickname` | boolean | false | Show nickname for right messages |
| `isShowTimeInBubble` | boolean | true | Show timestamp inside bubble |
| `cellSpacing` | number | 2 | Space between adjacent messages (vp) |
| `isShowSystemMessage` | boolean | true | Show system notification messages |
| `isShowUnsupportMessage` | boolean | true | Show unsupported message types |

### ⌨️ MessageInput

Message composition with multimedia support and custom actions.

```typescript
import { MessageInput, ChatMessageInputConfig } from '@tencentcloud/atomicx'

MessageInput({
  conversationID: 'c2c_user123',
  config: new ChatMessageInputConfig({
    isShowAudioRecorder: true,
    isShowImagePicker: true,
    isShowVideoPicker: true,
    isShowFilePicker: true,
    isShowEmojiPicker: true,
    placeholder: 'Type a message...'
  }),
  customActions: [
    {
      id: 'location',
      icon: $rawfile('messageinput/location_icon.svg'),
      action: () => {
        console.log('Share location')
      }
    }
  ]
})
```

### 📋 ConversationList

Displays conversation list with badges, pins, and context actions.

```typescript
import { ConversationList, ChatConversationConfig } from '@tencentcloud/atomicx'

ConversationList({
  config: new ChatConversationConfig({
    isShowAvatar: true,
    isShowTime: true,
    isShowBadge: true
  }),
  customActions: [
    {
      title: 'Mark as Read',
      iconName: $rawfile('conversationlist/ic_mark_read.svg'),
      action: (conversation: ConversationInfo) => {
        console.log('Mark as read:', conversation.ID)
      }
    }
  ],
  onConversationClick: (item: ConversationInfo) => {
    console.log('Open:', item.ID)
  }
})
```

### 👥 ContactList

Contact management with friend applications, groups, and blacklist.

```typescript
import { ContactList } from '@tencentcloud/atomicx'
import { ContactListStore } from '@tencentcloud/atomicxcore'

@Component
struct ContactsView {
  @State contactListStore: ContactListStore = ContactListStore.create()

  build() {
    ContactList({
      contactListStore: this.contactListStore,
      onContactClick: (contact: ContactInfo) => {
        // Show contact profile
      },
      onGroupClick: (group: ContactInfo) => {
        // Open group chat
      },
      onNewFriendsClick: () => {
        // Show friend applications
      },
      onGroupApplicationsClick: () => {
        // Show group applications
      },
      onGroupListClick: () => {
        // Show group list
      },
      onBlackListClick: () => {
        // Show blacklist
      }
    })
  }
}
```

### 🖼️ Multimedia Components

#### Image Picker & Viewer

```typescript
import { ImagePicker, ImageViewer } from '@tencentcloud/atomicx'

// Pick images
ImagePicker({
  maxSelectCount: 9,
  onSelected: (images: string[]) => {
    console.log('Selected images:', images)
  }
})

// View images
ImageViewer({
  images: ['url1', 'url2', 'url3'],
  currentIndex: 0,
  onClose: () => {
    console.log('Viewer closed')
  }
})
```

#### Video Picker & Player

```typescript
import { VideoPicker, VideoPlayer } from '@tencentcloud/atomicx'

// Pick video
VideoPicker({
  onSelected: (videoUrl: string) => {
    console.log('Selected video:', videoUrl)
  }
})

// Play video
VideoPlayer({
  videoUrl: 'file://path/to/video.mp4',
  autoPlay: true,
  showControls: true
})
```

#### Audio Recorder & Player

```typescript
import { AudioRecorder, AudioPlayer } from '@tencentcloud/atomicx'

// Record audio
AudioRecorder({
  maxDuration: 60,
  onRecordComplete: (audioPath: string, duration: number) => {
    console.log('Recorded audio:', audioPath, duration)
  }
})

// Play audio
AudioPlayer({
  audioUrl: 'file://path/to/audio.mp3',
  showControls: true
})
```

## ⚙️ Configuration System

### Configuration Priority

```
Local Config > Global AppBuilderConfig > Hardcoded Defaults
```

### Global Configuration

```typescript
import { AppBuilderConfig } from '@tencentcloud/atomicx'

// Configure globally
const config = AppBuilderConfig.getInstance()
config.isShowAvatar = true
config.isShowTime = true
config.hideSearch = false
config.conversationActionList = [
  ConversationAction.PIN,
  ConversationAction.MUTE,
  ConversationAction.DELETE
]
```

### Local Configuration (Recommended)

```typescript
// Create custom config for specific instance
const customConfig = new ChatMessageListConfig({
  isShowAvatar: false,
  alignment: MessageAlignment.center
})

MessageList({
  conversationID: 'group_123',
  config: customConfig
})
```

## 🎨 Theme System

### Colors

```typescript
import { ThemeState } from '@tencentcloud/atomicx'

@StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance()

// Usage
Column() {
  Text('Hello')
    .fontColor(this.themeState.colors.textColorPrimary)
    .backgroundColor(this.themeState.colors.bgColorOperate)
}
```

#### Available Color Tokens

```typescript
// Text Colors
themeState.colors.textColorPrimary      // Main text
themeState.colors.textColorSecondary    // Secondary text
themeState.colors.textColorTertiary     // Disabled/placeholder text
themeState.colors.textColorLink         // Links and highlights

// Background Colors
themeState.colors.bgColorOperate        // Main background
themeState.colors.bgColorInput          // Input background
themeState.colors.bgColorSecondary      // Secondary background

// UI Colors
themeState.colors.borderColor           // Borders
themeState.colors.dividerColor          // Dividers
themeState.colors.errorColor            // Error states
themeState.colors.successColor          // Success states
```

### Spacing

```typescript
import { Spacing } from '@tencentcloud/atomicx'

Column({ space: Spacing.m }) {
  // Consistent spacing
}
.padding({ 
  left: Spacing.l,
  right: Spacing.l,
  top: Spacing.m
})
```

#### Spacing Scale

| Token | Value | Use Case |
|-------|-------|----------|
| `Spacing.xs` | 4vp | Minimal spacing |
| `Spacing.s` | 8vp | Small gaps |
| `Spacing.m` | 16vp | Standard spacing |
| `Spacing.l` | 24vp | Large gaps |
| `Spacing.xl` | 32vp | Section spacing |

### Radius

```typescript
import { Radius } from '@tencentcloud/atomicx'

Column()
  .borderRadius(Radius.m)  // Rounded corners
```

## 🎯 Best Practices

### 1. Store Management

✅ **DO**: Create store at top level and pass down

```typescript
// HomePage.ets
@State contactListStore: ContactListStore = ContactListStore.create()

ContactsPage({
  contactListStore: this.contactListStore  // Pass down
})
```

❌ **DON'T**: Create multiple store instances

```typescript
// Creates separate instances - data won't sync!
@State store1: ContactListStore = ContactListStore.create()
@State store2: ContactListStore = ContactListStore.create()
```

### 2. Event Handling

✅ **DO**: Use callbacks for navigation

```typescript
ContactList({
  onContactClick: (contact) => {
    this.showChatDialog(contact.contactID)  // Handle at top level
  }
})
```

❌ **DON'T**: Handle navigation inside components

```typescript
// Component shouldn't know about navigation
ContactList({
  // Component directly navigates - tight coupling!
})
```

### 3. Configuration

✅ **DO**: Use typed configs

```typescript
const config = new ChatMessageListConfig({
  isShowAvatar: true,
  alignment: MessageAlignment.left
})
```

❌ **DON'T**: Use magic values

```typescript
// Hard to maintain and understand
MessageList({
  showAvatar: true,  // What's the default?
  align: 0          // What does 0 mean?
})
```

### 4. Resource Management

✅ **DO**: Clean up in `aboutToDisappear`

```typescript
aboutToDisappear() {
  this.unregisterListeners()
  this.dialogController?.close()
}
```

### 5. Type Safety

✅ **DO**: Use proper types

```typescript
@ObjectLink contactListStore: ContactListStore
```

❌ **DON'T**: Use `any` or suppress errors

```typescript
// Loses type safety!
contactListStore: any
```

## 📖 API Reference

### Core Exports

```typescript
// Base Components
export { Avatar, AvatarSize, AvatarShape }
export { ButtonControl, ButtonSize, ButtonType }
export { Badge, BadgeType }
export { AlertDialog, ActionSheet }

// IM Components
export { MessageList, MessageInput }
export { ConversationList }
export { ContactList }
export { ChatDialog }

// Configuration
export { ChatMessageListConfig, MessageListConfigProtocol }
export { ChatMessageInputConfig, MessageInputConfigProtocol }
export { ChatConversationConfig, ConversationListConfigProtocol }

// Theme
export { ThemeState, Colors, Fonts, Spacing, Radius }

// Utilities
export { AppBuilderConfig, TextUtils, ImageSizeUtil }
export { UserInteractionHelper, GroupPermissionManager }

// Multimedia
export { ImagePicker, ImageViewer }
export { VideoPicker, VideoPlayer }
export { AudioRecorder, AudioPlayer }
export { FilePicker, EmojiPicker }
```

### Component Props Reference

Full API documentation available at:
- [MessageList API](./src/main/ets/messagelist/README.md)
- [MessageInput API](./src/main/ets/messageinput/README.md)
- [ConversationList API](./src/main/ets/conversationlist/README.md)
- [ContactList API](./src/main/ets/contactlist/README.md)

## 🔍 Troubleshooting

### Common Issues

**Q: Messages not updating in real-time**
```typescript
// Ensure store is passed via @ObjectLink, not @Prop
@ObjectLink messageListStore: MessageListStore  // ✅ Observable
@Prop messageListStore: MessageListStore        // ❌ Not reactive
```

**Q: Dialog not closing properly**
```typescript
// Always set to undefined after closing
this.dialogController?.close()
this.dialogController = undefined  // ✅ Cleanup
```

**Q: Theme colors not applying**
```typescript
// Use @StorageLink to observe theme changes
@StorageLink('ThemeState') themeState: ThemeState  // ✅ Reactive
```

## 📚 Examples

See complete examples in:
- [`/chat/demo/`](../chat/demo/) - Full chat application
- [`/chat/uikit/`](../chat/uikit/) - Reusable pages

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guide](./CONTRIBUTING.md).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🔗 Related Links

- [atomicxcore SDK Documentation](../../core/README.md)
- [HarmonyOS Developer Guide](https://developer.harmonyos.com/)
- [Tencent Cloud IM](https://cloud.tencent.com/document/product/269)

## 📝 Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history and updates.

---

**Built with ❤️ for HarmonyOS by Tencent Cloud IM Team**
