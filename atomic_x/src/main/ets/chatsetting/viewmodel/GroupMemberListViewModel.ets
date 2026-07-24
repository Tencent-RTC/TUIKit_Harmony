import { GroupMember, GroupMemberFilterRole, GroupMemberStore } from '@tencentcloud/atomicxcore'
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers'
import { GroupMemberPaginationPolicy } from './GroupMemberPaginationPolicy'

@Observed
export class GroupMemberListViewModel {
  private readonly _groupID: string
  private readonly _groupMemberStore: GroupMemberStore
  private isLoadingMore: boolean = false

  constructor(groupID: string) {
    this._groupID = groupID
    this._groupMemberStore = GroupMemberStore.create(groupID)
    this._groupMemberStore.loadMembers([GroupMemberFilterRole.ALL])
  }

  get groupMemberStore(): GroupMemberStore {
    return this._groupMemberStore
  }

  get members(): GroupMember[] {
    return this._groupMemberStore.state.memberList
  }

  get hasMoreMembers(): boolean {
    return this._groupMemberStore.state.hasMoreMembers
  }

  loadMoreMembers(): void {
    if (!GroupMemberPaginationPolicy.shouldLoadMore(this.isLoadingMore, this._groupMemberStore.state.hasMoreMembers)) {
      return
    }
    this.isLoadingMore = true
    this._groupMemberStore.loadMoreMembers(new CompletionHandlerAdapter(() => {
      this.isLoadingMore = false
    }, () => {
      this.isLoadingMore = false
    }))
  }
}
