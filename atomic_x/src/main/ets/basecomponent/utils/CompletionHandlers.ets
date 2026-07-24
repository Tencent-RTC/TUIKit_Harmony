import { CompletionHandler } from '@tencentcloud/atomicxcore'
import { ContactInfo, GetContactInfoCompletionHandler } from '@tencentcloud/atomicxcore'
import {
  ConversationInfo,
  GetConversationInfoCompletionHandler
} from '@tencentcloud/atomicxcore'
import {
  CreateGroupCompletionHandler,
  GetGroupInfoCompletionHandler,
  GroupInfo
} from '@tencentcloud/atomicxcore'
import { GetMemberInfoCompletionHandler, GroupMember } from '@tencentcloud/atomicxcore'
import { MessageInfo } from '@tencentcloud/atomicxcore'
import { MergedMessageListCompletionHandler } from '@tencentcloud/atomicxcore'

export class CompletionHandlerAdapter implements CompletionHandler {
  private readonly success?: () => void
  private readonly failure?: (code: number, desc: string) => void

  constructor(success?: () => void, failure?: (code: number, desc: string) => void) {
    this.success = success
    this.failure = failure
  }

  onSuccess(): void {
    this.success?.()
  }

  onFailure(code: number, desc: string): void {
    this.failure?.(code, desc)
  }
}

export class GetConversationInfoCompletionHandlerAdapter implements GetConversationInfoCompletionHandler {
  private readonly success?: (conversationInfo: ConversationInfo) => void
  private readonly failure?: (code: number, desc: string) => void

  constructor(success?: (conversationInfo: ConversationInfo) => void, failure?: (code: number, desc: string) => void) {
    this.success = success
    this.failure = failure
  }

  onSuccess(conversationInfo: ConversationInfo): void {
    this.success?.(conversationInfo)
  }

  onFailure(code: number, desc: string): void {
    this.failure?.(code, desc)
  }
}

export class GetContactInfoCompletionHandlerAdapter implements GetContactInfoCompletionHandler {
  private readonly success?: (contactInfoList: ContactInfo[]) => void
  private readonly failure?: (code: number, desc: string) => void

  constructor(success?: (contactInfoList: ContactInfo[]) => void, failure?: (code: number, desc: string) => void) {
    this.success = success
    this.failure = failure
  }

  onSuccess(contactInfoList: ContactInfo[]): void {
    this.success?.(contactInfoList)
  }

  onFailure(code: number, desc: string): void {
    this.failure?.(code, desc)
  }
}

export class GetGroupInfoCompletionHandlerAdapter implements GetGroupInfoCompletionHandler {
  private readonly success?: (groupInfo: GroupInfo) => void
  private readonly failure?: (code: number, desc: string) => void

  constructor(success?: (groupInfo: GroupInfo) => void, failure?: (code: number, desc: string) => void) {
    this.success = success
    this.failure = failure
  }

  onSuccess(groupInfo: GroupInfo): void {
    this.success?.(groupInfo)
  }

  onFailure(code: number, desc: string): void {
    this.failure?.(code, desc)
  }
}

export class CreateGroupCompletionHandlerAdapter implements CreateGroupCompletionHandler {
  private readonly success?: (groupID: string) => void
  private readonly failure?: (code: number, desc: string) => void

  constructor(success?: (groupID: string) => void, failure?: (code: number, desc: string) => void) {
    this.success = success
    this.failure = failure
  }

  onSuccess(groupID: string): void {
    this.success?.(groupID)
  }

  onFailure(code: number, desc: string): void {
    this.failure?.(code, desc)
  }
}

export class GetMemberInfoCompletionHandlerAdapter implements GetMemberInfoCompletionHandler {
  private readonly success?: (memberInfoList: GroupMember[]) => void
  private readonly failure?: (code: number, desc: string) => void

  constructor(success?: (memberInfoList: GroupMember[]) => void, failure?: (code: number, desc: string) => void) {
    this.success = success
    this.failure = failure
  }

  onSuccess(memberInfoList: GroupMember[]): void {
    this.success?.(memberInfoList)
  }

  onFailure(code: number, desc: string): void {
    this.failure?.(code, desc)
  }
}

export class MergedMessageListCompletionHandlerAdapter implements MergedMessageListCompletionHandler {
  private readonly success?: (messageList: MessageInfo[]) => void
  private readonly failure?: (code: number, desc: string) => void

  constructor(success?: (messageList: MessageInfo[]) => void, failure?: (code: number, desc: string) => void) {
    this.success = success
    this.failure = failure
  }

  onSuccess(messageList: MessageInfo[]): void {
    this.success?.(messageList)
  }

  onFailure(code: number, desc: string): void {
    this.failure?.(code, desc)
  }
}
