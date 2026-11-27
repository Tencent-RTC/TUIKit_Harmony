import { CompletionHandler } from '../../api/Define';
import { SearchOption, SearchStore, SearchType } from '../../api/search/SearchStore';
@Observed
export declare class SearchStoreImpl extends SearchStore {
    private currentKeywordList;
    private currentOption;
    private messageSearchCursor;
    constructor();
    search(keywordList: string[], option?: SearchOption, completion?: CompletionHandler): void;
    searchMore(searchType: SearchType, completion?: CompletionHandler): void;
    private resetSearchData;
    private searchFriendsInternal;
    private searchGroupsInternal;
    private searchGroupMembersInternal;
    private searchMessagesInternal;
    private updateMessageResults;
    private fetchConversationInfoForMessageResults;
    private convertToUserProfile;
    private convertToFriendSearchInfo;
    private convertToGroupSearchInfo;
    private convertToGroupJoinOption;
    private convertToGroupInviteOption;
    private convertToMessageSearchResultItem;
    private convertToV2TIMElemType;
}
