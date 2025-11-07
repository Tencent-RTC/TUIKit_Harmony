/**
 * IM SDK Error Code Constants
 * Based on TUITool.m setupIMErrorMap
 */
export class IMErrorCode {
  // Success code
  static readonly ERR_SUCC = 0;
  
  // General error codes
  static readonly ERR_IN_PROGESS = 6015;
  static readonly ERR_INVALID_PARAMETERS = 6017;
  static readonly ERR_IO_OPERATION_FAILED = 6022;
  static readonly ERR_INVALID_JSON = 6027;
  static readonly ERR_OUT_OF_MEMORY = 6028;
  static readonly ERR_PARSE_RESPONSE_FAILED = 6001;
  static readonly ERR_SERIALIZE_REQ_FAILED = 6002;
  static readonly ERR_SDK_NOT_INITIALIZED = 6013;
  static readonly ERR_LOADMSG_FAILED = 6005;
  static readonly ERR_DATABASE_OPERATE_FAILED = 6019;
  static readonly ERR_SDK_COMM_CROSS_THREAD = 7001;
  static readonly ERR_SDK_COMM_TINYID_EMPTY = 7002;
  static readonly ERR_SDK_COMM_INVALID_IDENTIFIER = 7003;
  static readonly ERR_SDK_COMM_FILE_NOT_FOUND = 7004;
  static readonly ERR_SDK_COMM_FILE_TOO_LARGE = 7005;
  static readonly ERR_SDK_COMM_FILE_SIZE_EMPTY = 7006;
  static readonly ERR_SDK_COMM_FILE_OPEN_FAILED = 7007;
  static readonly ERR_SDK_INTERFACE_NOT_SUPPORT = 7013;
  
  // Additional general error codes
  static readonly ERR_NO_SUCC_RESULT = 6003;
  static readonly ERR_TO_USER_INVALID = 6011;
  static readonly ERR_REQUEST_TIMEOUT = 6012;
  static readonly ERR_INIT_CORE_FAIL = 6018;
  static readonly ERR_EXPIRED_SESSION_NODE = 6020;
  static readonly ERR_LOGGED_OUT_BEFORE_LOGIN_FINISHED = 6023;
  static readonly ERR_TLSSDK_NOT_INITIALIZED = 6024;
  static readonly ERR_TLSSDK_USER_NOT_FOUND = 6025;

  // Account error codes
  static readonly ERR_SDK_NOT_LOGGED_IN = 6014;
  static readonly ERR_NO_PREVIOUS_LOGIN = 6026;
  static readonly ERR_USER_SIG_EXPIRED = 6206;
  static readonly ERR_LOGIN_KICKED_OFF_BY_OTHER = 6208;
  static readonly ERR_SDK_ACCOUNT_LOGIN_IN_PROCESS = 7501;
  static readonly ERR_SDK_ACCOUNT_LOGOUT_IN_PROCESS = 7502;
  static readonly ERR_SDK_ACCOUNT_TLS_INIT_FAILED = 7503;
  static readonly ERR_SDK_ACCOUNT_TLS_NOT_INITIALIZED = 7504;
  static readonly ERR_SDK_ACCOUNT_TLS_TRANSPKG_ERROR = 7505;
  static readonly ERR_SDK_ACCOUNT_TLS_DECRYPT_FAILED = 7506;
  static readonly ERR_SDK_ACCOUNT_TLS_REQUEST_FAILED = 7507;
  static readonly ERR_SDK_ACCOUNT_TLS_REQUEST_TIMEOUT = 7508;

  // Message error codes
  static readonly ERR_INVALID_CONVERSATION = 6004;
  static readonly ERR_FILE_TRANS_AUTH_FAILED = 6006;
  static readonly ERR_FILE_TRANS_NO_SERVER = 6007;
  static readonly ERR_FILE_TRANS_UPLOAD_FAILED = 6008;
  static readonly ERR_IMAGE_UPLOAD_FAILED_NOTIMAGE = 6031;
  static readonly ERR_FILE_TRANS_DOWNLOAD_FAILED = 6009;
  static readonly ERR_HTTP_REQ_FAILED = 6010;
  static readonly ERR_INVALID_MSG_ELEM = 6016;
  static readonly ERR_INVALID_SDK_OBJECT = 6021;
  static readonly ERR_SDK_MSG_BODY_SIZE_LIMIT = 8001;
  static readonly ERR_SDK_MSG_KEY_REQ_DIFFER_RSP = 8002;
  static readonly ERR_SDK_IMAGE_CONVERT_ERROR = 8003;
  static readonly ERR_SDK_SIGNALING_INVALID_INVITE_ID = 8010;
  static readonly ERR_SDK_SIGNALING_NO_PERMISSION = 8011;
  static readonly ERR_SDK_SIGNALING_ALREADY_EXISTS = 8012;

  // Group error codes
  static readonly ERR_SDK_GROUP_INVALID_ID = 8501;
  static readonly ERR_SDK_GROUP_INVALID_NAME = 8502;
  static readonly ERR_SDK_GROUP_INVALID_INTRODUCTION = 8503;
  static readonly ERR_SDK_GROUP_INVALID_NOTIFICATION = 8504;
  static readonly ERR_SDK_GROUP_INVALID_FACE_URL = 8505;
  static readonly ERR_SDK_GROUP_INVALID_NAME_CARD = 8506;
  static readonly ERR_SDK_GROUP_MEMBER_COUNT_LIMIT = 8507;
  static readonly ERR_SDK_GROUP_JOIN_PRIVATE_GROUP_DENY = 8508;
  static readonly ERR_SDK_GROUP_INVITE_SUPER_DENY = 8509;
  static readonly ERR_SDK_GROUP_INVITE_NO_MEMBER = 8510;
  static readonly ERR_SDK_GROUP_ATTR_FREQUENCY_LIMIT = 8511;

  // Friendship error codes
  static readonly ERR_SDK_FRIENDSHIP_INVALID_PROFILE_KEY = 9001;
  static readonly ERR_SDK_FRIENDSHIP_INVALID_ADD_REMARK = 9002;
  static readonly ERR_SDK_FRIENDSHIP_INVALID_ADD_WORDING = 9003;
  static readonly ERR_SDK_FRIENDSHIP_INVALID_ADD_SOURCE = 9004;
  static readonly ERR_SDK_FRIENDSHIP_FRIEND_GROUP_EMPTY = 9005;

  // Network error codes
  static readonly ERR_SDK_NET_ENCODE_FAILED = 9501;
  static readonly ERR_SDK_NET_DECODE_FAILED = 9502;
  static readonly ERR_SDK_NET_AUTH_INVALID = 9503;
  static readonly ERR_SDK_NET_COMPRESS_FAILED = 9504;
  static readonly ERR_SDK_NET_UNCOMPRESS_FAILED = 9505;
  static readonly ERR_SDK_NET_FREQ_LIMIT = 9506;
  static readonly ERR_SDK_NET_REQ_COUNT_LIMIT = 9507;
  static readonly ERR_SDK_NET_DISCONNECT = 9508;
  static readonly ERR_SDK_NET_ALLREADY_CONN = 9509;
  static readonly ERR_SDK_NET_CONN_TIMEOUT = 9510;
  static readonly ERR_SDK_NET_CONN_REFUSE = 9511;
  static readonly ERR_SDK_NET_NET_UNREACH = 9512;
  static readonly ERR_SDK_NET_SOCKET_NO_BUFF = 9513;
  static readonly ERR_SDK_NET_RESET_BY_PEER = 9514;
  static readonly ERR_SDK_NET_SOCKET_INVALID = 9515;
  static readonly ERR_SDK_NET_HOST_GETADDRINFO_FAILED = 9516;
  static readonly ERR_SDK_NET_CONNECT_RESET = 9517;
  static readonly ERR_SDK_NET_WAIT_INQUEUE_TIMEOUT = 9518;
  static readonly ERR_SDK_NET_WAIT_SEND_TIMEOUT = 9519;
  static readonly ERR_SDK_NET_WAIT_ACK_TIMEOUT = 9520;
  static readonly ERR_SDK_NET_WAIT_SEND_REMAINING_TIMEOUT = 9521;
  static readonly ERR_SDK_NET_PKG_SIZE_LIMIT = 9522;
  static readonly ERR_SDK_NET_WAIT_SEND_TIMEOUT_NO_NETWORK = 9523;
  static readonly ERR_SDK_NET_WAIT_ACK_TIMEOUT_NO_NETWORK = 9524;
  static readonly ERR_SDK_NET_SEND_REMAINING_TIMEOUT_NO_NETWORK = 9525;

  // Server SSO error codes
  static readonly ERR_SVR_SSO_CONNECT_LIMIT = -302;
  static readonly ERR_SVR_SSO_VCODE = -10000;
  static readonly ERR_SVR_SSO_D2_EXPIRED = -10001;
  static readonly ERR_SVR_SSO_A2_UP_INVALID = -10003;
  static readonly ERR_SVR_SSO_A2_DOWN_INVALID = -10004;
  static readonly ERR_SVR_SSO_EMPTY_KEY = -10005;
  static readonly ERR_SVR_SSO_UIN_INVALID = -10006;
  static readonly ERR_SVR_SSO_VCODE_TIMEOUT = -10007;
  static readonly ERR_SVR_SSO_NO_IMEI_AND_A2 = -10008;
  static readonly ERR_SVR_SSO_COOKIE_INVALID = -10009;
  static readonly ERR_SVR_SSO_DOWN_TIP = -10101;
  static readonly ERR_SVR_SSO_DISCONNECT = -10102;
  static readonly ERR_SVR_SSO_IDENTIFIER_INVALID = -10103;
  static readonly ERR_SVR_SSO_CLIENT_CLOSE = -10104;
  static readonly ERR_SVR_SSO_MSFSDK_QUIT = -10105;
  static readonly ERR_SVR_SSO_D2KEY_WRONG = -10106;
  static readonly ERR_SVR_SSO_UNSURPPORT = -10107;
  static readonly ERR_SVR_SSO_PREPAID_ARREARS = -10108;
  static readonly ERR_SVR_SSO_PACKET_WRONG = -10109;
  static readonly ERR_SVR_SSO_APPID_BLACK_LIST = -10110;
  static readonly ERR_SVR_SSO_CMD_BLACK_LIST = -10111;
  static readonly ERR_SVR_SSO_APPID_WITHOUT_USING = -10112;
  static readonly ERR_SVR_SSO_FREQ_LIMIT = -10113;
  static readonly ERR_SVR_SSO_OVERLOAD = -10114;

  // Server Resource error codes
  static readonly ERR_SVR_RES_NOT_FOUND = 114000;
  static readonly ERR_SVR_RES_ACCESS_DENY = 114001;
  static readonly ERR_SVR_RES_SIZE_LIMIT = 114002;
  static readonly ERR_SVR_RES_SEND_CANCEL = 114003;
  static readonly ERR_SVR_RES_READ_FAILED = 114004;
  static readonly ERR_SVR_RES_TRANSFER_TIMEOUT = 114005;
  static readonly ERR_SVR_RES_INVALID_PARAMETERS = 114011;
  static readonly ERR_SVR_RES_INVALID_FILE_MD5 = 115066;
  static readonly ERR_SVR_RES_INVALID_PART_MD5 = 115068;

  // Server Common error codes
  static readonly ERR_SVR_COMM_INVALID_HTTP_URL = 60002;
  static readonly ERR_SVR_COMM_REQ_JSON_PARSE_FAILED = 60003;
  static readonly ERR_SVR_COMM_INVALID_ACCOUNT = 60004;
  static readonly ERR_SVR_COMM_INVALID_ACCOUNT_EX = 60005;
  static readonly ERR_SVR_COMM_INVALID_SDKAPPID = 60006;
  static readonly ERR_SVR_COMM_REST_FREQ_LIMIT = 60007;
  static readonly ERR_SVR_COMM_REQUEST_TIMEOUT = 60008;
  static readonly ERR_SVR_COMM_INVALID_RES = 60009;
  static readonly ERR_SVR_COMM_ID_NOT_ADMIN = 60010;
  static readonly ERR_SVR_COMM_SDKAPPID_FREQ_LIMIT = 60011;
  static readonly ERR_SVR_COMM_SDKAPPID_MISS = 60012;
  static readonly ERR_SVR_COMM_RSP_JSON_PARSE_FAILED = 60013;
  static readonly ERR_SVR_COMM_EXCHANGE_ACCOUNT_TIMEUT = 60014;
  static readonly ERR_SVR_COMM_INVALID_ID_FORMAT = 60015;
  static readonly ERR_SVR_COMM_SDKAPPID_FORBIDDEN = 60016;
  static readonly ERR_SVR_COMM_REQ_FORBIDDEN = 60017;
  static readonly ERR_SVR_COMM_REQ_FREQ_LIMIT = 60018;
  static readonly ERR_SVR_COMM_REQ_FREQ_LIMIT_EX = 60019;
  static readonly ERR_SVR_COMM_INVALID_SERVICE = 60020;
  static readonly ERR_SVR_COMM_SENSITIVE_TEXT = 80001;
  static readonly ERR_SVR_COMM_BODY_SIZE_LIMIT = 80002;

  // Server Account error codes
  static readonly ERR_SVR_ACCOUNT_USERSIG_EXPIRED = 70001;
  static readonly ERR_SVR_ACCOUNT_USERSIG_EMPTY = 70002;
  static readonly ERR_SVR_ACCOUNT_USERSIG_CHECK_FAILED = 70003;
  static readonly ERR_SVR_ACCOUNT_USERSIG_CHECK_FAILED_EX = 70005;
  static readonly ERR_SVR_ACCOUNT_USERSIG_MISMATCH_PUBLICKEY = 70009;
  static readonly ERR_SVR_ACCOUNT_USERSIG_MISMATCH_ID = 70013;
  static readonly ERR_SVR_ACCOUNT_USERSIG_MISMATCH_SDKAPPID = 70014;
  static readonly ERR_SVR_ACCOUNT_USERSIG_PUBLICKEY_NOT_FOUND = 70016;
  static readonly ERR_SVR_ACCOUNT_SDKAPPID_NOT_FOUND = 70020;
  static readonly ERR_SVR_ACCOUNT_FREQ_LIMIT = 70050;
  static readonly ERR_SVR_ACCOUNT_BLACKLIST = 70051;
  static readonly ERR_SVR_ACCOUNT_INVALID_USERSIG = 70052;
  static readonly ERR_SVR_ACCOUNT_NOT_FOUND = 70107;
  static readonly ERR_SVR_ACCOUNT_SEC_RSTR = 70114;
  static readonly ERR_SVR_ACCOUNT_INTERNAL_TIMEOUT = 70169;
  static readonly ERR_SVR_ACCOUNT_INVALID_COUNT = 70206;
  static readonly ERR_SVR_ACCOUNT_COUNT_LIMIT = 70398;
  static readonly ERR_SVR_ACCOUNT_INVALID_PARAMETERS = 70402;
  static readonly ERR_SVR_ACCOUNT_ADMIN_REQUIRED = 70403;
  static readonly ERR_SVR_ACCOUNT_INTERNAL_ERROR = 70500;

  // Server Profile error codes
  static readonly ERR_SVR_PROFILE_INVALID_PARAMETERS = 40001;
  static readonly ERR_SVR_PROFILE_ACCOUNT_MISS = 40002;
  static readonly ERR_SVR_PROFILE_ACCOUNT_NOT_FOUND = 40003;
  static readonly ERR_SVR_PROFILE_ADMIN_REQUIRED = 40004;
  static readonly ERR_SVR_PROFILE_SENSITIVE_TEXT = 40005;
  static readonly ERR_SVR_PROFILE_INTERNAL_ERROR = 40006;
  static readonly ERR_SVR_PROFILE_READ_PERMISSION_REQUIRED = 40007;
  static readonly ERR_SVR_PROFILE_WRITE_PERMISSION_REQUIRED = 40008;
  static readonly ERR_SVR_PROFILE_TAG_NOT_FOUND = 40009;
  static readonly ERR_SVR_PROFILE_SIZE_LIMIT = 40601;
  static readonly ERR_SVR_PROFILE_VALUE_ERROR = 40605;
  static readonly ERR_SVR_PROFILE_INVALID_VALUE_FORMAT = 40610;

  // Server Friendship error codes
  static readonly ERR_SVR_FRIENDSHIP_INVALID_PARAMETERS = 30001;
  static readonly ERR_SVR_FRIENDSHIP_INVALID_SDKAPPID = 30002;
  static readonly ERR_SVR_FRIENDSHIP_ACCOUNT_NOT_FOUND = 30003;
  static readonly ERR_SVR_FRIENDSHIP_ADMIN_REQUIRED = 30004;
  static readonly ERR_SVR_FRIENDSHIP_SENSITIVE_TEXT = 30005;
  static readonly ERR_SVR_FRIENDSHIP_INTERNAL_ERROR = 30006;
  static readonly ERR_SVR_FRIENDSHIP_NET_TIMEOUT = 30007;
  static readonly ERR_SVR_FRIENDSHIP_WRITE_CONFLICT = 30008;
  static readonly ERR_SVR_FRIENDSHIP_ADD_FRIEND_DENY = 30009;
  static readonly ERR_SVR_FRIENDSHIP_COUNT_LIMIT = 30010;
  static readonly ERR_SVR_FRIENDSHIP_GROUP_COUNT_LIMIT = 30011;
  static readonly ERR_SVR_FRIENDSHIP_PENDENCY_LIMIT = 30012;
  static readonly ERR_SVR_FRIENDSHIP_BLACKLIST_LIMIT = 30013;
  static readonly ERR_SVR_FRIENDSHIP_PEER_FRIEND_LIMIT = 30014;
  static readonly ERR_SVR_FRIENDSHIP_IN_SELF_BLACKLIST = 30515;
  static readonly ERR_SVR_FRIENDSHIP_ALLOW_TYPE_DENY_ANY = 30516;
  static readonly ERR_SVR_FRIENDSHIP_IN_PEER_BLACKLIST = 30525;
  static readonly ERR_SVR_FRIENDSHIP_ALLOW_TYPE_NEED_CONFIRM = 30539;
  static readonly ERR_SVR_FRIENDSHIP_ADD_FRIEND_SEC_RSTR = 30540;
  static readonly ERR_SVR_FRIENDSHIP_PENDENCY_NOT_FOUND = 30614;
  static readonly ERR_SVR_FRIENDSHIP_DEL_NONFRIEND = 31704;
  static readonly ERR_SVR_FRIENDSHIP_DEL_FRIEND_SEC_RSTR = 31707;
  static readonly ERR_SVR_FRIENDSHIP_ACCOUNT_NOT_FOUND_EX = 31804;

  // Server Conversation error codes
  static readonly ERR_SVR_CONV_ACCOUNT_NOT_FOUND = 50001;
  static readonly ERR_SVR_CONV_INVALID_PARAMETERS = 50002;
  static readonly ERR_SVR_CONV_ADMIN_REQUIRED = 50003;
  static readonly ERR_SVR_CONV_INTERNAL_ERROR = 50004;
  static readonly ERR_SVR_CONV_NET_TIMEOUT = 50005;

  // Server Message error codes
  static readonly ERR_SVR_MSG_PKG_PARSE_FAILED = 20001;
  static readonly ERR_SVR_MSG_INTERNAL_AUTH_FAILED = 20002;
  static readonly ERR_SVR_MSG_INVALID_ID = 20003;
  static readonly ERR_SVR_MSG_NET_ERROR = 20004;
  static readonly ERR_SVR_MSG_INTERNAL_ERROR1 = 20005;
  static readonly ERR_SVR_MSG_PUSH_DENY = 20006;
  static readonly ERR_SVR_MSG_IN_PEER_BLACKLIST = 20007;
  static readonly ERR_SVR_MSG_BOTH_NOT_FRIEND = 20009;
  static readonly ERR_SVR_MSG_NOT_PEER_FRIEND = 20010;
  static readonly ERR_SVR_MSG_NOT_SELF_FRIEND = 20011;
  static readonly ERR_SVR_MSG_SHUTUP_DENY = 20012;
  static readonly ERR_SVR_MSG_REVOKE_TIME_LIMIT = 20016;
  static readonly ERR_SVR_MSG_DEL_RAMBLE_INTERNAL_ERROR = 20018;
  static readonly ERR_SVR_MSG_JSON_PARSE_FAILED = 90001;
  static readonly ERR_SVR_MSG_INVALID_JSON_BODY_FORMAT = 90002;
  static readonly ERR_SVR_MSG_INVALID_TO_ACCOUNT = 90003;
  static readonly ERR_SVR_MSG_INVALID_RAND = 90005;
  static readonly ERR_SVR_MSG_INVALID_TIMESTAMP = 90006;
  static readonly ERR_SVR_MSG_BODY_NOT_ARRAY = 90007;
  static readonly ERR_SVR_MSG_ADMIN_REQUIRED = 90009;
  static readonly ERR_SVR_MSG_INVALID_JSON_FORMAT = 90010;
  static readonly ERR_SVR_MSG_TO_ACCOUNT_COUNT_LIMIT = 90011;
  static readonly ERR_SVR_MSG_TO_ACCOUNT_NOT_FOUND = 90012;
  static readonly ERR_SVR_MSG_TIME_LIMIT = 90026;
  static readonly ERR_SVR_MSG_INVALID_SYNCOTHERMACHINE = 90031;
  static readonly ERR_SVR_MSG_INVALID_MSGLIFETIME = 90044;
  static readonly ERR_SVR_MSG_ACCOUNT_NOT_FOUND = 90048;
  static readonly ERR_SVR_MSG_INTERNAL_ERROR2 = 90994;
  static readonly ERR_SVR_MSG_INTERNAL_ERROR3 = 90995;
  static readonly ERR_SVR_MSG_INTERNAL_ERROR4 = 91000;
  static readonly ERR_SVR_MSG_INTERNAL_ERROR5 = 90992;
  static readonly ERR_SVR_MSG_BODY_SIZE_LIMIT = 93000;
  static readonly ERR_SVR_MSG_LONGPOLLING_COUNT_LIMIT = 91101;

  // Server Group error codes
  static readonly ERR_SVR_GROUP_INTERNAL_ERROR = 10002;
  static readonly ERR_SVR_GROUP_API_NAME_ERROR = 10003;
  static readonly ERR_SVR_GROUP_INVALID_PARAMETERS = 10004;
  static readonly ERR_SVR_GROUP_ACOUNT_COUNT_LIMIT = 10005;
  static readonly ERR_SVR_GROUP_FREQ_LIMIT = 10006;
  static readonly ERR_SVR_GROUP_PERMISSION_DENY = 10007;
  static readonly ERR_SVR_GROUP_INVALID_REQ = 10008;
  static readonly ERR_SVR_GROUP_SUPER_NOT_ALLOW_QUIT = 10009;
  static readonly ERR_SVR_GROUP_NOT_FOUND = 10010;
  static readonly ERR_SVR_GROUP_JSON_PARSE_FAILED = 10011;
  static readonly ERR_SVR_GROUP_INVALID_ID = 10012;
  static readonly ERR_SVR_GROUP_ALLREADY_MEMBER = 10013;
  static readonly ERR_SVR_GROUP_FULL_MEMBER_COUNT = 10014;
  static readonly ERR_SVR_GROUP_INVALID_GROUPID = 10015;
  static readonly ERR_SVR_GROUP_REJECT_FROM_THIRDPARTY = 10016;
  static readonly ERR_SVR_GROUP_SHUTUP_DENY = 10017;
  static readonly ERR_SVR_GROUP_RSP_SIZE_LIMIT = 10018;
  static readonly ERR_SVR_GROUP_ACCOUNT_NOT_FOUND = 10019;
  static readonly ERR_SVR_GROUP_GROUPID_IN_USED = 10021;
  static readonly ERR_SVR_GROUP_SEND_MSG_FREQ_LIMIT = 10023;
  static readonly ERR_SVR_GROUP_REQ_ALLREADY_BEEN_PROCESSED = 10024;
  static readonly ERR_SVR_GROUP_GROUPID_IN_USED_FOR_SUPER = 10025;
  static readonly ERR_SVR_GROUP_SDKAPPID_DENY = 10026;
  static readonly ERR_SVR_GROUP_REVOKE_MSG_NOT_FOUND = 10030;
  static readonly ERR_SVR_GROUP_REVOKE_MSG_TIME_LIMIT = 10031;
  static readonly ERR_SVR_GROUP_REVOKE_MSG_DENY = 10032;
  static readonly ERR_SVR_GROUP_NOT_ALLOW_REVOKE_MSG = 10033;
  static readonly ERR_SVR_GROUP_REMOVE_MSG_DENY = 10034;
  static readonly ERR_SVR_GROUP_NOT_ALLOW_REMOVE_MSG = 10035;
  static readonly ERR_SVR_GROUP_AVCHATROOM_COUNT_LIMIT = 10036;
  static readonly ERR_SVR_GROUP_COUNT_LIMIT = 10037;
  static readonly ERR_SVR_GROUP_MEMBER_COUNT_LIMIT = 10038;

  /**
   * Get error message by error code
   * @param code Error code
   * @param defaultMsg Default message if code not found
   * @returns Error message
   */
  static getErrorMessage(code: number, defaultMsg?: string): Resource | string {
    const errorMessages = new Map<number, Resource>();
    
    // Success code
    errorMessages.set(IMErrorCode.ERR_SUCC, $r('app.string.error_code_success'));
    
    // General errors
    errorMessages.set(IMErrorCode.ERR_IN_PROGESS, $r('app.string.error_code_in_progress'));
    errorMessages.set(IMErrorCode.ERR_INVALID_PARAMETERS, $r('app.string.error_code_invalid_parameters'));
    errorMessages.set(IMErrorCode.ERR_IO_OPERATION_FAILED, $r('app.string.error_code_io_operation_failed'));
    errorMessages.set(IMErrorCode.ERR_INVALID_JSON, $r('app.string.error_code_invalid_json'));
    errorMessages.set(IMErrorCode.ERR_OUT_OF_MEMORY, $r('app.string.error_code_out_of_memory'));
    errorMessages.set(IMErrorCode.ERR_PARSE_RESPONSE_FAILED, $r('app.string.error_code_parse_response_failed'));
    errorMessages.set(IMErrorCode.ERR_SERIALIZE_REQ_FAILED, $r('app.string.error_code_serialize_request_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_NOT_INITIALIZED, $r('app.string.error_code_sdk_not_initialized'));
    errorMessages.set(IMErrorCode.ERR_LOADMSG_FAILED, $r('app.string.error_code_load_message_failed'));
    errorMessages.set(IMErrorCode.ERR_DATABASE_OPERATE_FAILED, $r('app.string.error_code_database_operation_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_COMM_CROSS_THREAD, $r('app.string.error_code_cross_thread_operation'));
    errorMessages.set(IMErrorCode.ERR_SDK_COMM_TINYID_EMPTY, $r('app.string.error_code_tiny_id_empty'));
    errorMessages.set(IMErrorCode.ERR_SDK_COMM_INVALID_IDENTIFIER, $r('app.string.error_code_invalid_identifier'));
    errorMessages.set(IMErrorCode.ERR_SDK_COMM_FILE_NOT_FOUND, $r('app.string.error_code_file_not_found'));
    errorMessages.set(IMErrorCode.ERR_SDK_COMM_FILE_TOO_LARGE, $r('app.string.error_code_file_too_large'));
    errorMessages.set(IMErrorCode.ERR_SDK_COMM_FILE_SIZE_EMPTY, $r('app.string.error_code_empty_file'));
    errorMessages.set(IMErrorCode.ERR_SDK_COMM_FILE_OPEN_FAILED, $r('app.string.error_code_file_open_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_INTERFACE_NOT_SUPPORT, $r('app.string.error_code_interface_not_supported'));
    errorMessages.set(IMErrorCode.ERR_NO_SUCC_RESULT, $r('app.string.error_code_no_success_result'));
    errorMessages.set(IMErrorCode.ERR_TO_USER_INVALID, $r('app.string.error_code_invalid_receiver'));
    errorMessages.set(IMErrorCode.ERR_REQUEST_TIMEOUT, $r('app.string.error_code_request_timeout'));
    errorMessages.set(IMErrorCode.ERR_INIT_CORE_FAIL, $r('app.string.error_code_init_core_failed'));
    errorMessages.set(IMErrorCode.ERR_EXPIRED_SESSION_NODE, $r('app.string.error_code_expired_session_node'));
    errorMessages.set(IMErrorCode.ERR_LOGGED_OUT_BEFORE_LOGIN_FINISHED, $r('app.string.error_code_logged_out_before_login_finished'));
    errorMessages.set(IMErrorCode.ERR_TLSSDK_NOT_INITIALIZED, $r('app.string.error_code_tls_sdk_not_initialized'));
    errorMessages.set(IMErrorCode.ERR_TLSSDK_USER_NOT_FOUND, $r('app.string.error_code_tls_sdk_user_not_found'));

    // Account errors
    errorMessages.set(IMErrorCode.ERR_SDK_NOT_LOGGED_IN, $r('app.string.error_code_not_logged_in'));
    errorMessages.set(IMErrorCode.ERR_NO_PREVIOUS_LOGIN, $r('app.string.error_code_no_previous_login'));
    errorMessages.set(IMErrorCode.ERR_USER_SIG_EXPIRED, $r('app.string.error_code_user_signature_expired'));
    errorMessages.set(IMErrorCode.ERR_LOGIN_KICKED_OFF_BY_OTHER, $r('app.string.error_code_kicked_off_by_other_login'));
    errorMessages.set(IMErrorCode.ERR_SDK_ACCOUNT_LOGIN_IN_PROCESS, $r('app.string.error_code_login_in_process'));
    errorMessages.set(IMErrorCode.ERR_SDK_ACCOUNT_LOGOUT_IN_PROCESS, $r('app.string.error_code_logout_in_process'));
    errorMessages.set(IMErrorCode.ERR_SDK_ACCOUNT_TLS_INIT_FAILED, $r('app.string.error_code_tls_init_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_ACCOUNT_TLS_NOT_INITIALIZED, $r('app.string.error_code_tls_not_initialized'));
    errorMessages.set(IMErrorCode.ERR_SDK_ACCOUNT_TLS_TRANSPKG_ERROR, $r('app.string.error_code_tls_transpkg_error'));
    errorMessages.set(IMErrorCode.ERR_SDK_ACCOUNT_TLS_DECRYPT_FAILED, $r('app.string.error_code_tls_decrypt_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_ACCOUNT_TLS_REQUEST_FAILED, $r('app.string.error_code_tls_request_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_ACCOUNT_TLS_REQUEST_TIMEOUT, $r('app.string.error_code_tls_request_timeout'));

    // Message errors
    errorMessages.set(IMErrorCode.ERR_INVALID_CONVERSATION, $r('app.string.error_code_invalid_conversation'));
    errorMessages.set(IMErrorCode.ERR_FILE_TRANS_AUTH_FAILED, $r('app.string.error_code_file_transfer_auth_failed'));
    errorMessages.set(IMErrorCode.ERR_FILE_TRANS_NO_SERVER, $r('app.string.error_code_no_file_transfer_server'));
    errorMessages.set(IMErrorCode.ERR_FILE_TRANS_UPLOAD_FAILED, $r('app.string.error_code_file_upload_failed'));
    errorMessages.set(IMErrorCode.ERR_IMAGE_UPLOAD_FAILED_NOTIMAGE, $r('app.string.error_code_upload_failed_not_image'));
    errorMessages.set(IMErrorCode.ERR_FILE_TRANS_DOWNLOAD_FAILED, $r('app.string.error_code_file_download_failed'));
    errorMessages.set(IMErrorCode.ERR_HTTP_REQ_FAILED, $r('app.string.error_code_http_request_failed'));
    errorMessages.set(IMErrorCode.ERR_INVALID_MSG_ELEM, $r('app.string.error_code_invalid_message_element'));
    errorMessages.set(IMErrorCode.ERR_INVALID_SDK_OBJECT, $r('app.string.error_code_invalid_sdk_object'));
    errorMessages.set(IMErrorCode.ERR_SDK_MSG_BODY_SIZE_LIMIT, $r('app.string.error_code_message_body_size_limit_exceeded'));
    errorMessages.set(IMErrorCode.ERR_SDK_MSG_KEY_REQ_DIFFER_RSP, $r('app.string.error_code_message_key_req_differ_rsp'));
    errorMessages.set(IMErrorCode.ERR_SDK_IMAGE_CONVERT_ERROR, $r('app.string.error_code_image_convert_error'));
    errorMessages.set(IMErrorCode.ERR_SDK_SIGNALING_INVALID_INVITE_ID, $r('app.string.error_code_signaling_invalid_invite_id'));
    errorMessages.set(IMErrorCode.ERR_SDK_SIGNALING_NO_PERMISSION, $r('app.string.error_code_signaling_no_permission'));
    errorMessages.set(IMErrorCode.ERR_SDK_SIGNALING_ALREADY_EXISTS, $r('app.string.error_code_signaling_already_exists'));

    // Group errors
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_INVALID_ID, $r('app.string.error_code_invalid_group_id'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_INVALID_NAME, $r('app.string.error_code_invalid_group_name'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_INVALID_INTRODUCTION, $r('app.string.error_code_invalid_group_introduction'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_INVALID_NOTIFICATION, $r('app.string.error_code_invalid_group_notification'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_INVALID_FACE_URL, $r('app.string.error_code_invalid_group_face_url'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_INVALID_NAME_CARD, $r('app.string.error_code_invalid_group_name_card'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_MEMBER_COUNT_LIMIT, $r('app.string.error_code_group_member_count_limit_exceeded'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_JOIN_PRIVATE_GROUP_DENY, $r('app.string.error_code_join_private_group_denied'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_INVITE_SUPER_DENY, $r('app.string.error_code_invite_super_group_denied'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_INVITE_NO_MEMBER, $r('app.string.error_code_invite_no_member'));
    errorMessages.set(IMErrorCode.ERR_SDK_GROUP_ATTR_FREQUENCY_LIMIT, $r('app.string.error_code_group_attr_frequency_limit'));

    // Friendship errors
    errorMessages.set(IMErrorCode.ERR_SDK_FRIENDSHIP_INVALID_PROFILE_KEY, $r('app.string.error_code_invalid_profile_key'));
    errorMessages.set(IMErrorCode.ERR_SDK_FRIENDSHIP_INVALID_ADD_REMARK, $r('app.string.error_code_invalid_add_remark'));
    errorMessages.set(IMErrorCode.ERR_SDK_FRIENDSHIP_INVALID_ADD_WORDING, $r('app.string.error_code_invalid_add_wording'));
    errorMessages.set(IMErrorCode.ERR_SDK_FRIENDSHIP_INVALID_ADD_SOURCE, $r('app.string.error_code_invalid_add_source'));
    errorMessages.set(IMErrorCode.ERR_SDK_FRIENDSHIP_FRIEND_GROUP_EMPTY, $r('app.string.error_code_friend_group_empty'));

    // Network errors
    errorMessages.set(IMErrorCode.ERR_SDK_NET_ENCODE_FAILED, $r('app.string.error_code_network_encode_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_DECODE_FAILED, $r('app.string.error_code_network_decode_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_AUTH_INVALID, $r('app.string.error_code_network_auth_invalid'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_COMPRESS_FAILED, $r('app.string.error_code_network_compress_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_UNCOMPRESS_FAILED, $r('app.string.error_code_network_uncompress_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_FREQ_LIMIT, $r('app.string.error_code_network_freq_limit'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_REQ_COUNT_LIMIT, $r('app.string.error_code_network_req_count_limit'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_DISCONNECT, $r('app.string.error_code_network_disconnected'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_ALLREADY_CONN, $r('app.string.error_code_network_already_connected'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_CONN_TIMEOUT, $r('app.string.error_code_connection_timeout'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_CONN_REFUSE, $r('app.string.error_code_connection_refused'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_NET_UNREACH, $r('app.string.error_code_network_unreachable'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_SOCKET_NO_BUFF, $r('app.string.error_code_socket_no_buffer'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_RESET_BY_PEER, $r('app.string.error_code_reset_by_peer'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_SOCKET_INVALID, $r('app.string.error_code_socket_invalid'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_HOST_GETADDRINFO_FAILED, $r('app.string.error_code_host_getaddrinfo_failed'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_CONNECT_RESET, $r('app.string.error_code_connect_reset'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_WAIT_INQUEUE_TIMEOUT, $r('app.string.error_code_wait_inqueue_timeout'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_WAIT_SEND_TIMEOUT, $r('app.string.error_code_wait_send_timeout'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_WAIT_ACK_TIMEOUT, $r('app.string.error_code_wait_ack_timeout'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_WAIT_SEND_REMAINING_TIMEOUT, $r('app.string.error_code_wait_send_remaining_timeout'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_PKG_SIZE_LIMIT, $r('app.string.error_code_pkg_size_limit'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_WAIT_SEND_TIMEOUT_NO_NETWORK, $r('app.string.error_code_wait_send_timeout_no_network'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_WAIT_ACK_TIMEOUT_NO_NETWORK, $r('app.string.error_code_wait_ack_timeout_no_network'));
    errorMessages.set(IMErrorCode.ERR_SDK_NET_SEND_REMAINING_TIMEOUT_NO_NETWORK, $r('app.string.error_code_send_remaining_timeout_no_network'));

    // Server SSO errors
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_CONNECT_LIMIT, $r('app.string.error_code_server_connection_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_VCODE, $r('app.string.error_code_server_verification_code'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_EMPTY_KEY, $r('app.string.error_code_server_empty_key'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_UIN_INVALID, $r('app.string.error_code_server_invalid_uin'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_VCODE_TIMEOUT, $r('app.string.error_code_server_verification_timeout'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_COOKIE_INVALID, $r('app.string.error_code_server_invalid_cookie'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_DOWN_TIP, $r('app.string.error_code_server_down_tip'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_DISCONNECT, $r('app.string.error_code_server_disconnect'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_IDENTIFIER_INVALID, $r('app.string.error_code_server_invalid_identifier'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_CLIENT_CLOSE, $r('app.string.error_code_server_client_close'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_MSFSDK_QUIT, $r('app.string.error_code_server_msfsdk_quit'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_UNSURPPORT, $r('app.string.error_code_server_unsupported'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_PREPAID_ARREARS, $r('app.string.error_code_server_prepaid_arrears'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_PACKET_WRONG, $r('app.string.error_code_server_packet_wrong'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_APPID_BLACK_LIST, $r('app.string.error_code_server_appid_blacklist'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_CMD_BLACK_LIST, $r('app.string.error_code_server_cmd_blacklist'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_APPID_WITHOUT_USING, $r('app.string.error_code_server_appid_without_using'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_FREQ_LIMIT, $r('app.string.error_code_server_freq_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_OVERLOAD, $r('app.string.error_code_server_overload'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_D2_EXPIRED, $r('app.string.error_code_server_d2_expired'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_A2_UP_INVALID, $r('app.string.error_code_server_a2_up_invalid'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_A2_DOWN_INVALID, $r('app.string.error_code_server_a2_down_invalid'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_NO_IMEI_AND_A2, $r('app.string.error_code_server_no_imei_and_a2'));
    errorMessages.set(IMErrorCode.ERR_SVR_SSO_D2KEY_WRONG, $r('app.string.error_code_server_d2key_wrong'));

    // Server Resource errors
    errorMessages.set(IMErrorCode.ERR_SVR_RES_NOT_FOUND, $r('app.string.error_code_server_resource_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_RES_ACCESS_DENY, $r('app.string.error_code_server_resource_access_denied'));
    errorMessages.set(IMErrorCode.ERR_SVR_RES_SIZE_LIMIT, $r('app.string.error_code_server_resource_size_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_RES_SEND_CANCEL, $r('app.string.error_code_server_resource_send_cancel'));
    errorMessages.set(IMErrorCode.ERR_SVR_RES_READ_FAILED, $r('app.string.error_code_server_resource_read_failed'));
    errorMessages.set(IMErrorCode.ERR_SVR_RES_TRANSFER_TIMEOUT, $r('app.string.error_code_server_resource_transfer_timeout'));
    errorMessages.set(IMErrorCode.ERR_SVR_RES_INVALID_PARAMETERS, $r('app.string.error_code_server_resource_invalid_parameters'));
    errorMessages.set(IMErrorCode.ERR_SVR_RES_INVALID_FILE_MD5, $r('app.string.error_code_server_resource_invalid_file_md5'));
    errorMessages.set(IMErrorCode.ERR_SVR_RES_INVALID_PART_MD5, $r('app.string.error_code_server_resource_invalid_part_md5'));

    // Server Common errors
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_INVALID_HTTP_URL, $r('app.string.error_code_server_invalid_http_url'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_REQ_JSON_PARSE_FAILED, $r('app.string.error_code_server_req_json_parse_failed'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_INVALID_ACCOUNT, $r('app.string.error_code_server_invalid_account'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_INVALID_ACCOUNT_EX, $r('app.string.error_code_server_invalid_account_ex'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_INVALID_SDKAPPID, $r('app.string.error_code_server_invalid_sdkappid'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_REST_FREQ_LIMIT, $r('app.string.error_code_server_rest_freq_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_REQUEST_TIMEOUT, $r('app.string.error_code_server_request_timeout'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_INVALID_RES, $r('app.string.error_code_server_invalid_resource'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_ID_NOT_ADMIN, $r('app.string.error_code_server_id_not_admin'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_SDKAPPID_FREQ_LIMIT, $r('app.string.error_code_server_sdkappid_freq_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_SDKAPPID_MISS, $r('app.string.error_code_server_sdkappid_miss'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_RSP_JSON_PARSE_FAILED, $r('app.string.error_code_server_rsp_json_parse_failed'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_EXCHANGE_ACCOUNT_TIMEUT, $r('app.string.error_code_server_exchange_account_timeout'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_INVALID_ID_FORMAT, $r('app.string.error_code_server_invalid_id_format'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_SDKAPPID_FORBIDDEN, $r('app.string.error_code_server_sdkappid_forbidden'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_REQ_FORBIDDEN, $r('app.string.error_code_server_req_forbidden'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_REQ_FREQ_LIMIT, $r('app.string.error_code_server_req_freq_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_REQ_FREQ_LIMIT_EX, $r('app.string.error_code_server_req_freq_limit_ex'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_INVALID_SERVICE, $r('app.string.error_code_server_invalid_service'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_SENSITIVE_TEXT, $r('app.string.error_code_server_sensitive_text'));
    errorMessages.set(IMErrorCode.ERR_SVR_COMM_BODY_SIZE_LIMIT, $r('app.string.error_code_server_body_size_limit'));

    // Server Account errors
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_USERSIG_EXPIRED, $r('app.string.error_code_server_account_usersig_expired'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_USERSIG_EMPTY, $r('app.string.error_code_server_account_usersig_empty'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_USERSIG_CHECK_FAILED, $r('app.string.error_code_server_account_usersig_check_failed'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_USERSIG_CHECK_FAILED_EX, $r('app.string.error_code_server_account_usersig_check_failed_ex'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_USERSIG_MISMATCH_PUBLICKEY, $r('app.string.error_code_server_account_usersig_mismatch_publickey'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_USERSIG_MISMATCH_ID, $r('app.string.error_code_server_account_usersig_mismatch_id'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_USERSIG_MISMATCH_SDKAPPID, $r('app.string.error_code_server_account_usersig_mismatch_sdkappid'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_USERSIG_PUBLICKEY_NOT_FOUND, $r('app.string.error_code_server_account_usersig_publickey_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_SDKAPPID_NOT_FOUND, $r('app.string.error_code_server_account_sdkappid_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_FREQ_LIMIT, $r('app.string.error_code_server_account_freq_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_BLACKLIST, $r('app.string.error_code_server_account_blacklist'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_INVALID_USERSIG, $r('app.string.error_code_server_account_invalid_usersig'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_NOT_FOUND, $r('app.string.error_code_server_account_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_SEC_RSTR, $r('app.string.error_code_server_account_sec_rstr'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_INTERNAL_TIMEOUT, $r('app.string.error_code_server_account_internal_timeout'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_INVALID_COUNT, $r('app.string.error_code_server_account_invalid_count'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_COUNT_LIMIT, $r('app.string.error_code_server_account_count_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_INVALID_PARAMETERS, $r('app.string.error_code_server_account_invalid_parameters'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_ADMIN_REQUIRED, $r('app.string.error_code_server_account_admin_required'));
    errorMessages.set(IMErrorCode.ERR_SVR_ACCOUNT_INTERNAL_ERROR, $r('app.string.error_code_server_account_internal_error'));

    // Server Profile errors
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_INVALID_PARAMETERS, $r('app.string.error_code_server_profile_invalid_parameters'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_ACCOUNT_MISS, $r('app.string.error_code_server_profile_account_miss'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_ACCOUNT_NOT_FOUND, $r('app.string.error_code_server_profile_account_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_ADMIN_REQUIRED, $r('app.string.error_code_server_profile_admin_required'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_SENSITIVE_TEXT, $r('app.string.error_code_server_profile_sensitive_text'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_INTERNAL_ERROR, $r('app.string.error_code_server_profile_internal_error'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_READ_PERMISSION_REQUIRED, $r('app.string.error_code_server_profile_read_permission_required'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_WRITE_PERMISSION_REQUIRED, $r('app.string.error_code_server_profile_write_permission_required'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_TAG_NOT_FOUND, $r('app.string.error_code_server_profile_tag_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_SIZE_LIMIT, $r('app.string.error_code_server_profile_size_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_VALUE_ERROR, $r('app.string.error_code_server_profile_value_error'));
    errorMessages.set(IMErrorCode.ERR_SVR_PROFILE_INVALID_VALUE_FORMAT, $r('app.string.error_code_server_profile_invalid_value_format'));

    // Server Friendship errors
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_INVALID_PARAMETERS, $r('app.string.error_code_server_friendship_invalid_parameters'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_INVALID_SDKAPPID, $r('app.string.error_code_server_friendship_invalid_sdkappid'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_ACCOUNT_NOT_FOUND, $r('app.string.error_code_server_friendship_account_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_ADMIN_REQUIRED, $r('app.string.error_code_server_friendship_admin_required'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_SENSITIVE_TEXT, $r('app.string.error_code_server_friendship_sensitive_text'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_INTERNAL_ERROR, $r('app.string.error_code_server_friendship_internal_error'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_NET_TIMEOUT, $r('app.string.error_code_server_friendship_net_timeout'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_WRITE_CONFLICT, $r('app.string.error_code_server_friendship_write_conflict'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_ADD_FRIEND_DENY, $r('app.string.error_code_server_friendship_add_friend_deny'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_COUNT_LIMIT, $r('app.string.error_code_server_friendship_count_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_GROUP_COUNT_LIMIT, $r('app.string.error_code_server_friendship_group_count_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_PENDENCY_LIMIT, $r('app.string.error_code_server_friendship_pendency_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_BLACKLIST_LIMIT, $r('app.string.error_code_server_friendship_blacklist_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_PEER_FRIEND_LIMIT, $r('app.string.error_code_server_friendship_peer_friend_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_IN_SELF_BLACKLIST, $r('app.string.error_code_server_friendship_in_self_blacklist'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_ALLOW_TYPE_DENY_ANY, $r('app.string.error_code_server_friendship_allow_type_deny_any'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_IN_PEER_BLACKLIST, $r('app.string.error_code_server_friendship_in_peer_blacklist'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_ALLOW_TYPE_NEED_CONFIRM, $r('app.string.error_code_server_friendship_allow_type_need_confirm'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_ADD_FRIEND_SEC_RSTR, $r('app.string.error_code_server_friendship_add_friend_sec_rstr'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_PENDENCY_NOT_FOUND, $r('app.string.error_code_server_friendship_pendency_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_DEL_NONFRIEND, $r('app.string.error_code_server_friendship_del_nonfriend'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_DEL_FRIEND_SEC_RSTR, $r('app.string.error_code_server_friendship_del_friend_sec_rstr'));
    errorMessages.set(IMErrorCode.ERR_SVR_FRIENDSHIP_ACCOUNT_NOT_FOUND_EX, $r('app.string.error_code_server_friendship_account_not_found_ex'));

    // Server Conversation errors
    errorMessages.set(IMErrorCode.ERR_SVR_CONV_ACCOUNT_NOT_FOUND, $r('app.string.error_code_server_conv_account_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_CONV_INVALID_PARAMETERS, $r('app.string.error_code_server_conv_invalid_parameters'));
    errorMessages.set(IMErrorCode.ERR_SVR_CONV_ADMIN_REQUIRED, $r('app.string.error_code_server_conv_admin_required'));
    errorMessages.set(IMErrorCode.ERR_SVR_CONV_INTERNAL_ERROR, $r('app.string.error_code_server_conv_internal_error'));
    errorMessages.set(IMErrorCode.ERR_SVR_CONV_NET_TIMEOUT, $r('app.string.error_code_server_conv_net_timeout'));

    // Server Message errors
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_PKG_PARSE_FAILED, $r('app.string.error_code_server_msg_pkg_parse_failed'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INTERNAL_AUTH_FAILED, $r('app.string.error_code_server_msg_internal_auth_failed'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INVALID_ID, $r('app.string.error_code_server_msg_invalid_id'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_NET_ERROR, $r('app.string.error_code_server_msg_net_error'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INTERNAL_ERROR1, $r('app.string.error_code_server_msg_internal_error1'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_PUSH_DENY, $r('app.string.error_code_server_msg_push_deny'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_IN_PEER_BLACKLIST, $r('app.string.error_code_server_msg_in_peer_blacklist'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_BOTH_NOT_FRIEND, $r('app.string.error_code_server_msg_both_not_friend'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_NOT_PEER_FRIEND, $r('app.string.error_code_server_msg_not_peer_friend'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_NOT_SELF_FRIEND, $r('app.string.error_code_server_msg_not_self_friend'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_SHUTUP_DENY, $r('app.string.error_code_server_msg_shutup_deny'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_REVOKE_TIME_LIMIT, $r('app.string.error_code_server_msg_revoke_time_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_DEL_RAMBLE_INTERNAL_ERROR, $r('app.string.error_code_server_msg_del_ramble_internal_error'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_JSON_PARSE_FAILED, $r('app.string.error_code_server_msg_json_parse_failed'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INVALID_JSON_BODY_FORMAT, $r('app.string.error_code_server_msg_invalid_json_body_format'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INVALID_TO_ACCOUNT, $r('app.string.error_code_server_msg_invalid_to_account'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INVALID_RAND, $r('app.string.error_code_server_msg_invalid_rand'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INVALID_TIMESTAMP, $r('app.string.error_code_server_msg_invalid_timestamp'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_BODY_NOT_ARRAY, $r('app.string.error_code_server_msg_body_not_array'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_ADMIN_REQUIRED, $r('app.string.error_code_server_msg_admin_required'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INVALID_JSON_FORMAT, $r('app.string.error_code_server_msg_invalid_json_format'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_TO_ACCOUNT_COUNT_LIMIT, $r('app.string.error_code_server_msg_to_account_count_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_TO_ACCOUNT_NOT_FOUND, $r('app.string.error_code_server_msg_to_account_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_TIME_LIMIT, $r('app.string.error_code_server_msg_time_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INVALID_SYNCOTHERMACHINE, $r('app.string.error_code_server_msg_invalid_syncothermachine'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INVALID_MSGLIFETIME, $r('app.string.error_code_server_msg_invalid_msglifetime'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_ACCOUNT_NOT_FOUND, $r('app.string.error_code_server_msg_account_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INTERNAL_ERROR2, $r('app.string.error_code_server_msg_internal_error2'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INTERNAL_ERROR3, $r('app.string.error_code_server_msg_internal_error3'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INTERNAL_ERROR4, $r('app.string.error_code_server_msg_internal_error4'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_INTERNAL_ERROR5, $r('app.string.error_code_server_msg_internal_error5'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_BODY_SIZE_LIMIT, $r('app.string.error_code_server_msg_body_size_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_MSG_LONGPOLLING_COUNT_LIMIT, $r('app.string.error_code_server_msg_longpolling_count_limit'));

    // Server Group errors
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_INTERNAL_ERROR, $r('app.string.error_code_server_group_internal_error'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_API_NAME_ERROR, $r('app.string.error_code_server_group_api_name_error'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_INVALID_PARAMETERS, $r('app.string.error_code_server_group_invalid_parameters'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_ACOUNT_COUNT_LIMIT, $r('app.string.error_code_server_group_account_count_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_FREQ_LIMIT, $r('app.string.error_code_server_group_freq_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_PERMISSION_DENY, $r('app.string.error_code_server_group_permission_deny'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_INVALID_REQ, $r('app.string.error_code_server_group_invalid_req'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_SUPER_NOT_ALLOW_QUIT, $r('app.string.error_code_server_group_super_not_allow_quit'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_NOT_FOUND, $r('app.string.error_code_server_group_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_JSON_PARSE_FAILED, $r('app.string.error_code_server_group_json_parse_failed'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_INVALID_ID, $r('app.string.error_code_server_group_invalid_id'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_ALLREADY_MEMBER, $r('app.string.error_code_server_group_already_member'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_FULL_MEMBER_COUNT, $r('app.string.error_code_server_group_full_member_count'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_INVALID_GROUPID, $r('app.string.error_code_server_group_invalid_groupid'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_REJECT_FROM_THIRDPARTY, $r('app.string.error_code_server_group_reject_from_thirdparty'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_SHUTUP_DENY, $r('app.string.error_code_server_group_shutup_deny'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_RSP_SIZE_LIMIT, $r('app.string.error_code_server_group_rsp_size_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_ACCOUNT_NOT_FOUND, $r('app.string.error_code_server_group_account_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_GROUPID_IN_USED, $r('app.string.error_code_server_group_groupid_in_used'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_SEND_MSG_FREQ_LIMIT, $r('app.string.error_code_server_group_send_msg_freq_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_REQ_ALLREADY_BEEN_PROCESSED, $r('app.string.error_code_server_group_req_already_been_processed'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_GROUPID_IN_USED_FOR_SUPER, $r('app.string.error_code_server_group_groupid_in_used_for_super'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_SDKAPPID_DENY, $r('app.string.error_code_server_group_sdkappid_deny'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_REVOKE_MSG_NOT_FOUND, $r('app.string.error_code_server_group_revoke_msg_not_found'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_REVOKE_MSG_TIME_LIMIT, $r('app.string.error_code_server_group_revoke_msg_time_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_REVOKE_MSG_DENY, $r('app.string.error_code_server_group_revoke_msg_deny'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_NOT_ALLOW_REVOKE_MSG, $r('app.string.error_code_server_group_not_allow_revoke_msg'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_REMOVE_MSG_DENY, $r('app.string.error_code_server_group_remove_msg_deny'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_NOT_ALLOW_REMOVE_MSG, $r('app.string.error_code_server_group_not_allow_remove_msg'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_AVCHATROOM_COUNT_LIMIT, $r('app.string.error_code_server_group_avchatroom_count_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_COUNT_LIMIT, $r('app.string.error_code_server_group_count_limit'));
    errorMessages.set(IMErrorCode.ERR_SVR_GROUP_MEMBER_COUNT_LIMIT, $r('app.string.error_code_server_group_member_count_limit'));

    return errorMessages.get(code) || defaultMsg || $r('app.string.error_code_unknown_format', code.toString());
  }

  /**
   * Check if error code indicates file size issue
   * @param code Error code
   * @returns true if it's a file size related error
   */
  static isFileSizeError(code: number): boolean {
    return code === IMErrorCode.ERR_SDK_COMM_FILE_TOO_LARGE ||
           code === IMErrorCode.ERR_SVR_SSO_VCODE ||
           code === IMErrorCode.ERR_SVR_RES_SIZE_LIMIT ||
           code === IMErrorCode.ERR_SVR_COMM_BODY_SIZE_LIMIT ||
           code === IMErrorCode.ERR_SDK_MSG_BODY_SIZE_LIMIT;
  }

  /**
   * Check if error code indicates empty file
   * @param code Error code
   * @returns true if it's an empty file error
   */
  static isEmptyFileError(code: number): boolean {
    return code === IMErrorCode.ERR_SDK_COMM_FILE_SIZE_EMPTY;
  }

  /**
   * Check if error code indicates network issue
   * @param code Error code
   * @returns true if it's a network related error
   */
  static isNetworkError(code: number): boolean {
    return code >= IMErrorCode.ERR_SDK_NET_ENCODE_FAILED && 
           code <= IMErrorCode.ERR_SDK_NET_SEND_REMAINING_TIMEOUT_NO_NETWORK;
  }
}
