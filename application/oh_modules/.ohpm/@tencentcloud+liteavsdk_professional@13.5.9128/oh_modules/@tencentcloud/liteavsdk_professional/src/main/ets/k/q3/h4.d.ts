/**
 * 播放器SDK常量类
 */
export declare class TXVodConstants {
    /**
     * 图像平铺模式
     */
    static readonly RENDER_MODE_FULL_FILL_SCREEN = 0;
    static readonly RENDER_MODE_ADJUST_RESOLUTION = 1;
    /**
     * 图像渲染角度
     */
    static readonly RENDER_ROTATION_PORTRAIT = 0;
    static readonly RENDER_ROTATION_LANDSCAPE = 270;
    /**
     * 播放事件列表
     */
    static readonly VOD_PLAY_EVT_HIT_CACHE = 2002;
    static readonly VOD_PLAY_EVT_RCV_FIRST_I_FRAME = 2003;
    static readonly VOD_PLAY_EVT_PLAY_BEGIN = 2004;
    static readonly VOD_PLAY_EVT_PLAY_PROGRESS = 2005;
    static readonly VOD_PLAY_EVT_PLAY_END = 2006;
    static readonly VOD_PLAY_EVT_PLAY_LOADING = 2007;
    static readonly VOD_PLAY_EVT_START_VIDEO_DECODER = 2008;
    static readonly VOD_PLAY_EVT_CHANGE_RESOLUTION = 2009;
    static readonly VOD_PLAY_EVT_GET_PLAYINFO_SUCC = 2010;
    static readonly VOD_PLAY_EVT_CHANGE_ROTATION = 2011;
    static readonly VOD_PLAY_EVT_VOD_PLAY_PREPARED = 2013;
    static readonly VOD_PLAY_EVT_VOD_LOADING_END = 2014;
    static readonly VOD_PLAY_EVT_RCV_FIRST_AUDIO_FRAME = 2026;
    static readonly VOD_PLAY_WARNING_RECONNECT = 2103;
    static readonly VOD_PLAY_ERR_NET_DISCONNECT = -2301;
    static readonly VOD_PLAY_ERR_FILE_NOT_FOUND = -2303;
    static readonly VOD_PLAY_ERR_HEVC_DECODE_FAIL = -2304;
    static readonly VOD_PLAY_ERR_HLS_KEY = -2305;
    static readonly VOD_PLAY_ERR_GET_PLAYINFO_FAIL = -2306;
    static readonly VOD_PLAY_ERR_DRM = -6101;
    static readonly VOD_PLAY_WARNING_HW_ACCELERATION_FAIL = 1103;
    static readonly VOD_PLAY_ERR_INVALID_LICENCE = -5;
    static readonly VOD_PLAY_EVT_TCP_CONNECT_SUCC = 2016;
    static readonly VOD_PLAY_EVT_FIRST_VIDEO_PACKET = 2017;
    static readonly VOD_PLAY_EVT_DNS_RESOLVED = 2018;
    static readonly VOD_PLAY_EVT_SEEK_COMPLETE = 2019;
    static readonly VOD_PLAY_EVT_SELECT_TRACK_SUCCESS = 2020;
    static readonly VOD_PLAY_EVT_SELECT_TRACK_FAILURE = 2021;
    static readonly VOD_PLAY_EVT_VIDEO_SEI = 2030;
    static readonly VOD_PLAY_EVT_LOOP_ONCE_COMPLETE = 6001;
    static readonly VOD_PLAY_ERR_UNKNOW = -6001;
    static readonly VOD_PLAY_ERR_GENERAL = -6002;
    static readonly VOD_PLAY_ERR_DEMUXER_FAIL = -6003;
    static readonly VOD_PLAY_ERR_SYSTEM_PLAY_FAIL = -6004;
    static readonly VOD_PLAY_ERR_DEMUXER_TIMEOUT = -6005;
    static readonly VOD_PLAY_ERR_DECODE_VIDEO_FAIL = -6006;
    static readonly VOD_PLAY_ERR_DECODE_AUDIO_FAIL = -6007;
    static readonly VOD_PLAY_ERR_DECODE_SUBTITLE_FAIL = -6008;
    static readonly VOD_PLAY_ERR_RENDER_FAIL = -6009;
    static readonly VOD_PLAY_ERR_PROCESS_VIDEO_FAIL = -6010;
    static readonly VOD_PLAY_ERR_DOWNLOAD_FAIL = -6011;
    /**
     * 事件参数
     */
    static readonly EVT_UTC_TIME = "EVT_UTC_TIME";
    static readonly EVT_BLOCK_DURATION = "EVT_BLOCK_DURATION";
    static readonly EVT_TIME = "EVT_TIME";
    static readonly EVT_DESCRIPTION = "EVT_MSG";
    static readonly EVT_ERROR_CODE = "EVT_ERROR_CODE";
    static readonly EVT_PARAM1 = "EVT_PARAM1";
    static readonly EVT_PARAM2 = "EVT_PARAM2";
    static readonly EVT_GET_MSG = "EVT_GET_MSG";
    static readonly EVT_PLAY_COVER_URL = "EVT_PLAY_COVER_URL";
    static readonly EVT_PLAY_URL = "EVT_PLAY_URL";
    static readonly EVT_PLAY_NAME = "EVT_PLAY_NAME";
    static readonly EVT_PLAY_DESCRIPTION = "EVT_PLAY_DESCRIPTION";
    static readonly EVT_PLAY_PROGRESS_MS = "EVT_PLAY_PROGRESS_MS";
    static readonly EVT_PLAY_DURATION_MS = "EVT_PLAY_DURATION_MS";
    static readonly EVT_PLAY_PROGRESS = "EVT_PLAY_PROGRESS";
    static readonly EVT_PLAY_PDT_TIME_MS = "EVT_PLAY_PDT_TIME_MS";
    static readonly EVT_PLAY_DURATION = "EVT_PLAY_DURATION";
    static readonly EVT_PLAYABLE_DURATION_MS = "EVT_PLAYABLE_DURATION_MS";
    static readonly EVT_PLAYABLE_RATE = "EVT_PLAYABLE_RATE";
    static readonly EVT_USERID = "EVT_USERID";
    static readonly EVT_ID = "EVT_ID";
    static readonly EVT_REPORT_TOKEN = "EVT_REPORT_TOKEN";
    static readonly EVT_STREAM_TYPE = "EVT_STREAM_TYPE";
    static readonly EVT_PLAYABLE_DURATION = "EVT_PLAYABLE_DURATION";
    static readonly EVT_IMAGESPRIT_WEBVTTURL = "EVT_IMAGESPRIT_WEBVTTURL";
    static readonly EVT_IMAGESPRIT_IMAGEURL_LIST = "EVT_IMAGESPRIT_IMAGEURL_LIST";
    static readonly EVT_DRM_TYPE = "EVT_DRM_TYPE";
    static readonly EVT_CODEC_TYPE = "EVT_CODEC_TYPE";
    static readonly EVT_KEY_FRAME_CONTENT_LIST = "EVT_KEY_FRAME_CONTENT_LIST";
    static readonly EVT_KEY_FRAME_TIME_LIST = "EVT_KEY_FRAME_TIME_LIST";
    static readonly EVT_KEY_SELECT_TRACK_INDEX = "EVT_KEY_SELECT_TRACK_INDEX";
    static readonly EVT_KEY_SELECT_TRACK_ERROR_CODE = "EVT_KEY_SELECT_TRACK_ERROR_CODE";
    static readonly EVT_KEY_VIDEO_ROTATION = "EVT_KEY_VIDEO_ROTATION";
    static readonly EVT_KEY_WATER_MARK_TEXT = "EVT_KEY_WATER_MARK_TEXT";
    static readonly EVT_KEY_SEI_TYPE = "EVT_KEY_SEI_TYPE";
    static readonly EVT_KEY_SEI_SIZE = "EVT_KEY_SEI_SIZE";
    static readonly EVT_KEY_SEI_DATA = "EVT_KEY_SEI_DATA";
    /**
     * 网络状态通知
     */
    static readonly NET_STATUS_CPU_USAGE = "CPU_USAGE";
    static readonly NET_STATUS_VIDEO_WIDTH = "VIDEO_WIDTH";
    static readonly NET_STATUS_VIDEO_HEIGHT = "VIDEO_HEIGHT";
    static readonly NET_STATUS_VIDEO_FPS = "VIDEO_FPS";
    static readonly NET_STATUS_VIDEO_GOP = "VIDEO_GOP";
    static readonly NET_STATUS_VIDEO_BITRATE = "VIDEO_BITRATE";
    static readonly NET_STATUS_AUDIO_BITRATE = "AUDIO_BITRATE";
    static readonly NET_STATUS_NET_SPEED = "NET_SPEED";
    static readonly NET_STATUS_AUDIO_CACHE = "AUDIO_CACHE";
    static readonly NET_STATUS_VIDEO_CACHE = "VIDEO_CACHE";
    static readonly NET_STATUS_AUDIO_INFO = "AUDIO_PLAY_INFO";
    static readonly NET_STATUS_NET_JITTER = "NET_JITTER";
    static readonly NET_STATUS_SERVER_IP = "SERVER_IP";
    static readonly NET_STATUS_VIDEO_DPS = "VIDEO_DPS";
    static readonly NET_STATUS_QUALITY_LEVEL = "NET_QUALITY_LEVEL";
    /**
     * 媒资类型
     */
    static readonly MEDIA_TYPE_AUTO = 0;
    static readonly MEDIA_TYPE_HLS_VOD = 1;
    static readonly MEDIA_TYPE_HLS_LIVE = 2;
    static readonly MEDIA_TYPE_FILE_VOD = 3;
    static readonly MEDIA_TYPE_DASH_VOD = 4;
    static readonly INDEX_AUTO = -1;
    static readonly VOD_PLAY_MIMETYPE_TEXT_SRT = "text/x-subrip";
    static readonly VOD_PLAY_MIMETYPE_TEXT_VTT = "text/vtt";
    static readonly VOD_PLAY_MIMETYPE_H265 = "video/hevc";
    static readonly VOD_KEY_BACKUP_URL = "backup_url";
    static readonly VOD_KEY_MIMETYPE = "mimetype";
    static readonly AUDIO_NORMALIZATION_OFF = 1;
    static readonly AUDIO_NORMALIZATION_STANDARD = -17;
    static readonly AUDIO_NORMALIZATION_LOW = -25;
    static readonly AUDIO_NORMALIZATION_HIGH = -10;
    static readonly PLAYER_SYSTEM_MEDIA_PLAYER = 0;
    static readonly PLAYER_THUMB_PLAYER = 1;
    static readonly VOD_USE_DOWNLOADER = "USE_DOWNLOADER";
    static readonly VOD_KEY_CUSTOM_DATA = "VOD_KEY_CUSTOM_DATA";
}
