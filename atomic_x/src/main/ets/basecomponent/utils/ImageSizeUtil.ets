export interface SizeOptions {
  width: number,
  height: number
}

export class ImageSizeUtil {
  static readonly DEFAULT_MAX_SIZE: number = 190;
  static readonly DEFAULT_MIN_SIZE: number = 80;
  static readonly MIN_ASPECT_RATIO: number = 0.5;
  static readonly MAX_ASPECT_RATIO: number = 2.0;
  static readonly MEDIA_BUBBLE_MAX_SIZE: number = 200;
  static readonly MEDIA_BUBBLE_MIN_SIZE: number = 80;

  public static getSquareSize(): SizeOptions {
    return {
      width: ImageSizeUtil.DEFAULT_MAX_SIZE,
      height: ImageSizeUtil.DEFAULT_MAX_SIZE
    };
  }

  public static calculateMediaBubbleSize(originalWidth: number, originalHeight: number): SizeOptions {
    const width = originalWidth > 0 ? originalWidth : 100;
    const height = originalHeight > 0 ? originalHeight : 100;
    const ratio = width / height;
    if (ratio > 1) {
      return {
        width: ImageSizeUtil.MEDIA_BUBBLE_MAX_SIZE,
        height: ImageSizeUtil.clamp(ImageSizeUtil.MEDIA_BUBBLE_MAX_SIZE / ratio,
          ImageSizeUtil.MEDIA_BUBBLE_MIN_SIZE, ImageSizeUtil.MEDIA_BUBBLE_MAX_SIZE)
      };
    }
    return {
      width: ImageSizeUtil.clamp(ImageSizeUtil.MEDIA_BUBBLE_MAX_SIZE * ratio,
        ImageSizeUtil.MEDIA_BUBBLE_MIN_SIZE, ImageSizeUtil.MEDIA_BUBBLE_MAX_SIZE),
      height: ImageSizeUtil.MEDIA_BUBBLE_MAX_SIZE
    };
  }

  private static clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
  }

  public static calculateOptimalSize(
    originalWidth: number,
    originalHeight: number,
    maxSize: number = this.DEFAULT_MAX_SIZE,
    minSize: number = this.DEFAULT_MIN_SIZE,
    minAspectRatio: number = this.MIN_ASPECT_RATIO,
    maxAspectRatio: number = this.MAX_ASPECT_RATIO
  ): SizeOptions {
    // Calculate scale ratio
    const widthRatio = maxSize / originalWidth;
    const heightRatio = maxSize / originalHeight;
    const scale = Math.min(widthRatio, heightRatio, 1);

    // Calculate display dimensions
    let width = Math.min(originalWidth * scale, maxSize);
    let height = Math.min(originalHeight * scale, maxSize);

    // Adjust aspect ratio
    if (width / height < minAspectRatio) {
      width = Math.min(height * minAspectRatio, maxSize);
    } else if (width / height > maxAspectRatio) {
      height = Math.min(width / maxAspectRatio, maxSize);
    }

    // Ensure dimensions are not smaller than minimum size
    width = Math.max(width, minSize);
    height = Math.max(height, minSize);

    return { width, height };
  }
}