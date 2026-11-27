/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
/**
 * 下载回调类
 */
export type V2TIMDownloadCallback = (currentSize: number, totalSize: number) => void;
/**
 * 上传回调类
 */
export type V2TIMUploadCallback = (currentSize: number, totalSize: number) => void;
