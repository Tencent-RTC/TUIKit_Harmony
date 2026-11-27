/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 参数标志位，用来标识设置了哪些参数
 *
 * @author karlyczhang
 * @date 2024/03/13
 */
export const enum TPSubtitleParamFlag {
  UNKNOWN = 0,
  CANVAS_WIDTH = (1 << 0),
  CANVAS_HEIGHT = (1 << 1),
  FONT_SIZE = (1 << 2),
  FONT_COLOR = (1 << 3),
  OUTLINE_WIDTH = (1 << 4),
  OUTLINE_COLOR = (1 << 5),
  LINE_SPACE = (1 << 6),
  START_MARGIN = (1 << 7),
  END_MARGIN = (1 << 8),
  VERTICAL_MARGIN = (1 << 9),
  FONT_STYLE_BOLD = (1 << 10),
  FONT_SCALE = (1 << 11)
}

/**
 * 字体样式标志位，用来标识设置了哪些字体样式，暂时只支持粗体
 *
 * @author karlyczhang
 * @date 2024/03/13
 */
export const enum TPSubtitleFontStyle {
  UNKNOWN = 0,
  BOLD = (1 << 0)
}

/**
 * 字幕背景渲染参数
 *
 * @author jiesonchen
 * @date 2024/05/17
 */
export class TPSubtitleBackgroundParams {
  /**
   *  背景框的填充颜色，ARGB格式
   *  如果不设置，默认为透明(0)
   */
  backgroundColor: number;

  /**
   *  背景框相对字幕文本的左右边距, 尺寸是在画布中的尺寸，即参考基准是画布的宽高canvasWidth和canvasHeight
   *  如果不设置，默认为0
   */
  backgroundHorizontalMargin: number;

  /**
   *  背景框相对字幕文本的上下边距，尺寸是在画布中的尺寸，即参考基准是画布的宽高canvasWidth和canvasHeight
   *  如果不设置，默认为0
   */
  backgroundVerticalMargin: number;

  /**
   *  背景框边框的颜色，ARGB格式
   *  如果不设置，默认为透明(0),即没有边框
   */
  backgroundBorderColor: number;

  /**
   *  背景框边框的线宽，尺寸是在画布中的尺寸，即参考基准是画布的宽高canvasWidth和canvasHeight
   *  如果不设置，默认为0
   */
  backgroundBorderWidth: number;

  /**
   *  背景框的圆角半径相对于背景高度的比例,取值范围【0-0.5】
   *  如果不设置，默认为0
   */
  cornerRadiusToHeightRatio: number;
}

/**
 * 字幕渲染参数
 *
 * @author karlyczhang
 * @date 2024/03/13
 */
export class TPSubtitleRenderParams {
  /**
   * canvasWidth是字幕渲染画布的宽
   * canvasWidth和canvasHeight的比例必须和视频的宽高比一致，否则渲染出的字体会变形。
   * 如果不设置，播放器会取当前视频的大小作为渲染画布的大小。
   */
  canvasWidth: number;

  /** 字幕渲染画布的高 */
  canvasHeight: number;

  /** paramFlags标识设置哪些渲染参数 */
  paramFlags: number;

  /**
   * paramPriorityFlags标识设置了paramFlags的参数是否优先于其他设定值, 比如vtt文件里默认的字体大小/颜色/高度等
   * 当paramFlags对应位置位后再判断该参数的对应位
   */
  paramPriorityFlags: number;

  /**
   * font family name
   * familyName不受paramFlags的控制，字符串不为空则认为已设置，为空则认为未设置
   */
  familyName: string;

  /**
   * 字体大小
   * 如果设置了fontSize，则必须设置canvasWidth和canvasHeight，否则内部不知道以什么大小为参考来渲染字体
   * 如果设置了fontSize，paramFlags须置位TPSubtitleParamFlag.FONT_SIZE
   * 如果不设置fontSize，内部会使用默认的字体大小
   */
  fontSize: number;

  /**
   * 字体缩放比例 vtt css专用
   * 使用fontScale乘以vtt设定的font-size: em值再适应视频宽
   * 如果设置了fontScale，paramFlags须置位TPSubtitleParamFlag.FONT_SCALE
   * 最终字体像素为fontScale * vtt em * 16 * canvas width(video width) / default width(491)
   * fontScale默认1.0, 视频宽491像素时,中文字号设定为16像素大小, 将vtt文件内字体大小设定为1em(font-size: 1.00em;)
   * 参考https://developer.mozilla.org/zh-CN/docs/Web/CSS/font-size#ems
   * 如果未设置则采用fontSize
   */
  fontScale: number;

  /**
   * 字体颜色，ARGB格式
   * 如果设置了fontColor，paramFlags须置位TPSubtitleParamFlag.FONT_COLOR
   * 如果不设置，默认为白色不透明(0xFFFFFFFF)
   */
  fontColor: number;

  /** 字体样式，bit位或，见TPSubtitleFontStyle的定义。字体样式同样需要设置paramFlags */
  fontStyleFlags: number;

  /**
   * 描边宽度
   * 如果设置了outlineWidth，则必须设置canvasWidth和canvasHeight，否则内部不知道以什么大小为参考来渲染描边
   * 如果设置了outlineWidth，paramFlags须置位TPSubtitleParamFlag.OUTLINE_WIDTH
   * 如果不设置，内部会使用默认的描边宽度
   */
  outlineWidth: number;

  /**
   * 描边颜色，ARGB格式
   * 如果设置了outlineColor，paramFlags须置位TPSubtitleParamFlag.OUTLINE_COLOR
   * 如果不设置，默认为黑色不透明(0xFF000000)
   */
  outlineColor: number;

  /**
   * 行距 如果设置了lineSpace
   * 则必须设置canvasWidth和canvasHeight 如果设置了lineSpace，paramFlags须置位TPSubtitleParamFlag.LINE_SPACE
   * 如果不设置，内部会使用默认的行距
   */
  lineSpace: number;

  /**
   * 以下startMargin、endMargin和verticalMargin定义字幕的绘制区域，如果不设置，则使用字幕文件中的设置，如果字幕文件也没有定义，则使用默认的
   * 注意：一旦设置了startMargin、endMargin和yMargin，而字幕文件也定义了这几个参数的一个或多个，则会覆盖字幕文件中相应的参数。
   * 下面示意图描绘了水平书写方向下这几个参数的意义，请借助每个参数的注释来理解
   * -----------------------------------------------------------------------
   * |                                                                      |
   * |                                                                      |
   * |                                                                      |
   * |                        _________________________                     |
   * |----- startMargin -----|  This is subtitle text  |------endMargin-----|
   * |                       |_________________________|                    |
   * |                                    | verticalMargin                  |
   * -----------------------------------------------------------------------
   *
   */

  /**
   * startMargin是一个比例值，取值范围[0, 1]，即相对于视频画面大小的比例。
   * 沿着字幕文本方向的边距，根据不同的书写方向意义不同。
   * 对于水平书写方向，startMargin表示字幕左边距离视频画面左边的距离，比如startMargin=0.05则边距为视频宽度的0.05倍（5%）
   * 对于垂直书写方向（无论从右到左还是从左到右），startMargin表示字幕顶部距离视频画面顶部的距离，比如startMargin=0.05则边距为视频高度的0.05倍（5%）
   * 如果设置了startMargin，paramFlags须置位TPSubtitleParamFlag.START_MARGIN
   */
  startMargin: number;

  /**
   * endMargin是一个比例值，取值范围[0, 1]，即相对于视频画面大小的比例。
   * 沿着字幕文本方向的边距，根据不同的书写方向意义不同。
   * 对于水平书写方向，endMargin表示字幕右边距离视频画面右边的距离，比如endMargin=0.05则边距为视频宽度的0.05倍（5%）
   * 对于垂直书写方向（无论从右到左还是从左到右），endMargin表示字幕底部距离视频画面底部的距离，比如endMargin=0.05则边距为视频高度的0.05倍（5%）
   * 如果设置了endMargin，paramFlags须置位TPSubtitleParamFlag.END_MARGIN
   */
  endMargin: number;

  /**
   * 垂直字幕文本方向的边距，根据不同的书写方向意义不同。 vertialMarginn为一个比例值，取值范围[0, 1]，即相对于视频画面大小的比例
   * 对于水平书写方向，yMargin表示字幕底部距离视频画面底部的距离，比如yMargin=0.05则边距为视频高度的0.05倍（5%）
   * 对于垂直、从右至左书写方向，yMargin表示字幕右边距离视频画面右边的距离，比如yMargin=0.05则边距为视频宽度的0.05倍（5%）
   * 对于垂直、从左至右书写方向，yMargin表示字幕左边距离视频画面左边的距离，比如yMargin=0.05则边距为视频宽度的0.05倍（5%）
   * 如果设置了verticalMargin，paramFlags须置位TPSubtitleParamFlag.VERTICAL_MARGIN
   */
  verticalMargin: number;

  /**
   * 字幕背景参数
   */
  backgroundParams?: TPSubtitleBackgroundParams;
}
