/**
 * Copyright (c) 2021 Tencent. All rights reserved.
 * Module:   美颜与图像处理参数设置类
 * Function: 修改美颜、滤镜、绿幕等参数
 */
import image from '@ohos.multimedia.image';
/**
 * 美颜（磨皮）算法。
 *
 * TRTC 内置多种不同的磨皮算法，您可以选择最适合您产品定位的方案。
 */
export declare enum TXBeautyStyle {
    TXBeautyStyleSmooth = 0,
    TXBeautyStyleNature = 1,
    TXBeautyStylePitu = 2
}
export interface TXBeautyManager {
    /**
     * 设置美颜（磨皮）算法。
     *
     * TRTC 内置多种不同的磨皮算法，您可以选择最适合您产品定位的方案：
     * @param beautyStyle 美颜风格，TXBeautyStyleSmooth：光滑；TXBeautyStyleNature：自然；TXBeautyStylePitu：优图。
     */
    setBeautyStyle(beautyStyle: TXBeautyStyle): void;
    /**
     * 设置美颜级别。
     *
     * @param beautyLevel 美颜级别，取值范围 [0, 9]； 0 表示关闭，9 表示效果最明显。
     */
    setBeautyLevel(beautyLevel: number): void;
    /**
     * 设置美白级别。
     *
     * @param whitenessLevel 美白级别，取值范围 [0, 9]；0 表示关闭，9 表示效果最明显。
     */
    setWhitenessLevel(whitenessLevel: number): void;
    /**
     * 设置红润级别。
     *
     * @param ruddyLevel 红润级别，取值范围 [0, 9]；0 表示关闭，9 表示效果最明显。
     */
    setRuddyLevel(ruddyLevel: number): void;
    /**
     * 设置色彩滤镜效果。
     *
     * 色彩滤镜，是一张包含色彩映射关系的颜色查找表图片，您可以在我们提供的官方 Demo 中找到预先准备好的几张滤镜图片。
     * SDK 会根据该查找表中的映射关系，对摄像头采集出的原始视频画面进行二次处理，以达到预期的滤镜效果。
     * @param image 包含色彩映射关系的颜色查找表图片，必须是 png 格式。
     */
    setFilter(image: image.PixelMap | null): void;
    /**
     * 设置色彩滤镜的强度。
     *
     * 该数值越高，色彩滤镜的作用强度越明显，经过滤镜处理后的视频画面跟原画面的颜色差异越大。
     * 默认的滤镜浓度为 0.5，如果您觉得默认的滤镜效果不明显，可以设置为 0.5 以上的数字，最大值为 1。
     * @param strength 取值范围 [0, 1]，数值越大滤镜效果越明显，默认值为 0.5。
     */
    setFilterStrength(strength: number): void;
}
