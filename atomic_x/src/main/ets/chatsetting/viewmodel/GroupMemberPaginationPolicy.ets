export class GroupMemberPaginationPolicy {
  static shouldLoadMore(isLoadingMore: boolean, hasMoreMembers: boolean): boolean {
    return !isLoadingMore && hasMoreMembers
  }
}
