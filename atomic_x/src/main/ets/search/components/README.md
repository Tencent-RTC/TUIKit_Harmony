# SearchBar 组件使用指南

## 概述

`SearchBar` 是一个独立的搜索入口组件，参考 Flutter 的设计理念封装了所有搜索相关逻辑。您可以将其放置在任何页面顶部作为搜索入口，无需关心内部实现细节。

## 特性

- ✅ **独立封装**：所有搜索逻辑均在组件内部实现
- ✅ **简单易用**：对外仅暴露必要的回调接口
- ✅ **开箱即用**：无需手动管理弹窗状态
- ✅ **自动清理**：组件销毁时自动释放资源

## 基本用法

```typescript
import { SearchBar, ContactResultInfo, GroupResultInfo, MessageInConversationResultInfo } from '@tencentcloud/atomicx';

@Component
export struct YourPage {
  build() {
    Column() {
      // 放置搜索栏
      SearchBar({
        onContactSelect: (contact: ContactResultInfo) => {
          // 处理联系人选择
          console.log(`Selected contact: ${contact.userID}`);
        },
        onGroupSelect: (group: GroupResultInfo) => {
          // 处理群组选择
          console.log(`Selected group: ${group.groupID}`);
        },
        onMessageSelect: (message: MessageInConversationResultInfo) => {
          // 处理消息选择（点击具体消息）
          console.log(`Selected message in: ${message.conversationID}`);
        },
        onConversationSelect: (message: MessageInConversationResultInfo) => {
          // 处理会话选择（点击会话进入）
          console.log(`Selected conversation: ${message.conversationID}`);
        }
      })
      
      // 其他页面内容
    }
  }
}
```

## API 接口

### 回调函数

#### onContactSelect
```typescript
onContactSelect?: (contact: ContactResultInfo) => void
```
当用户选择联系人时触发。

**ContactResultInfo 字段：**
- `userID: string` - 用户 ID
- `userAvatar: string` - 用户头像 URL
- `nickname: string` - 用户昵称
- `friendRemark: string` - 好友备注

#### onGroupSelect
```typescript
onGroupSelect?: (group: GroupResultInfo) => void
```
当用户选择群组时触发。

**GroupResultInfo 字段：**
- `groupID: string` - 群组 ID
- `groupName: string` - 群组名称
- `groupAvatar: string` - 群组头像 URL

#### onMessageSelect
```typescript
onMessageSelect?: (message: MessageInConversationResultInfo) => void
```
当用户点击具体消息时触发（例如在搜索结果中点击某条消息，需要定位到该消息）。

**MessageInConversationResultInfo 字段：**
- `conversationID: string` - 会话 ID
- `conversationName: string` - 会话名称
- `conversationAvatar: string` - 会话头像 URL
- `message?: MessageInfo` - 消息对象（可选）

#### onConversationSelect
```typescript
onConversationSelect?: (message: MessageInConversationResultInfo) => void
```
当用户点击会话进入时触发（例如查看会话中的所有相关消息）。

## 完整示例

以下是 `ConversationsPage` 中的实际使用案例：

```typescript
import { SearchBar, ContactResultInfo, GroupResultInfo, MessageInConversationResultInfo } from '@tencentcloud/atomicx';

@Component
export struct ConversationsPage {
  onConversationClick?: (item: ConversationInfo) => void;
  onConversationClickWithMessage?: (item: ConversationInfo, locateMessage?: MessageInfo) => void;

  build() {
    Column() {
      // 标题栏
      this.LargeTitleBuilder()
      
      // 搜索栏
      if (!AppBuilderConfig.getInstance().hideSearch) {
        SearchBar({
          onContactSelect: (contact: ContactResultInfo) => {
            if (contact.userID) {
              this.showChatDialog(
                `c2c_${contact.userID}`,
                contact.friendRemark || contact.nickname || contact.userID,
                contact.userAvatar
              );
            }
          },
          onGroupSelect: (group: GroupResultInfo) => {
            if (group.groupID) {
              this.showChatDialog(
                `group_${group.groupID}`,
                group.groupName || group.groupID,
                group.groupAvatar
              );
            }
          },
          onMessageSelect: (message: MessageInConversationResultInfo) => {
            if (message.conversationID) {
              this.showChatDialog(
                message.conversationID,
                message.conversationName || 'Chat',
                message.conversationAvatar,
                message.message
              );
            }
          },
          onConversationSelect: (message: MessageInConversationResultInfo) => {
            if (message.conversationID) {
              this.showChatDialog(
                message.conversationID,
                message.conversationName || 'Chat',
                message.conversationAvatar,
                message.message
              );
            }
          }
        })
      }
      
      // 会话列表
      ConversationList({
        onConversationClick: (item: ConversationInfo) => {
          if (this.onConversationClick) {
            this.onConversationClick(item);
          }
        }
      })
    }
  }

  private showChatDialog(conversationID: string, title: string, avatarURL?: string, message?: MessageInfo): void {
    const conversationInfo = new ConversationInfo();
    conversationInfo.ID = conversationID;
    conversationInfo.title = title;
    conversationInfo.avatarURL = avatarURL ?? '';
    
    if (message && this.onConversationClickWithMessage) {
      this.onConversationClickWithMessage(conversationInfo, message);
    } else if (this.onConversationClick) {
      this.onConversationClick(conversationInfo);
    }
  }
}
```

## 与 Flutter 的对比

### Flutter SearchBar
```dart
SearchBar(
  onTap: () {
    // 打开搜索页面
  },
)
```

### HarmonyOS SearchBar
```typescript
SearchBar({
  onContactSelect: (contact) => { /* ... */ },
  onGroupSelect: (group) => { /* ... */ },
  onMessageSelect: (message) => { /* ... */ },
  onConversationSelect: (message) => { /* ... */ }
})
```

## 设计理念

1. **封装性**：内部管理所有弹窗状态和生命周期
2. **简洁性**：对外仅暴露必要的回调接口
3. **易用性**：开箱即用，无需额外配置
4. **安全性**：自动处理资源清理，避免内存泄漏

## 注意事项

1. **自动资源管理**：组件在 `aboutToDisappear` 时会自动关闭弹窗并释放资源
2. **回调都是可选的**：根据实际需求选择性实现回调函数
3. **UI 配置**：遵循 `AppBuilderConfig.getInstance().hideSearch` 配置

## 迁移指南

如果您的代码还在使用旧的 `SearchDialogBuilder` 方式，可以按以下步骤迁移：

### 旧方式（不推荐）
```typescript
@State searchDialogController: CustomDialogController | null = null;

@Builder
SearchBuilder() {
  Row() {
    // 搜索入口 UI
  }
  .onClick(() => {
    this.handleSearch();
  })
}

private handleSearch(): void {
  this.searchDialogController = new CustomDialogController({
    builder: this.SearchDialogBuilder,
    // ... 大量配置代码
  });
  this.searchDialogController.open();
}

@Builder
SearchDialogBuilder() {
  Column() {
    SearchListPage({
      // ... 大量回调代码
    })
  }
}
```

### 新方式（推荐）
```typescript
// 直接使用 SearchBar，无需状态变量和弹窗管理
SearchBar({
  onContactSelect: (contact) => { /* ... */ },
  onGroupSelect: (group) => { /* ... */ },
  onMessageSelect: (message) => { /* ... */ },
  onConversationSelect: (message) => { /* ... */ }
})
```

**优势**：
- ✅ 代码量减少 70%+
- ✅ 无需手动管理弹窗状态
- ✅ 自动处理资源清理
- ✅ 更易维护和测试
