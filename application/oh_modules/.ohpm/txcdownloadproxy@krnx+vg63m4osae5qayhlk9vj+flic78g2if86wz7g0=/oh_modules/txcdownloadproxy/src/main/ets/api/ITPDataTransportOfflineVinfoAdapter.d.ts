export interface ITPDataTransportOfflineVinfoAdapter {
    /**
     * 检查视频状态是否是离线视频
     *
     * @param vid 视频 vid
     * @param format 视频清晰度
     * @return 如果有离线视频记录，返回离线 vinfo，否则返回空
     */
    checkVideoStatus(vid: string, format: string): string;
    /**
     * 获取离线视频时长，离线下载广告需要用这个接口来决定播放的广告时长
     *
     * @param vid 视频 vid
     * @param format 视频清晰度
     * @return 找到对应离线视频记录返回对应视频时长，否则返回 0
     */
    getRecordDuration(vid: string, format: string): number;
}
