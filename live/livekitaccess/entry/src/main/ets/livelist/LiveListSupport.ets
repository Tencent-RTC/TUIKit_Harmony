export class LiveListPalette {
  static readonly background: string = 'rgba(15, 18, 26, 1)'
  static readonly secondaryText: string = 'rgba(255, 255, 255, 0.68)'
  static readonly defaultCoverURL: string =
    'https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/live/live_cover1.png'
}

export class LiveListImageLoader {
  static source(urlString: string): string {
    return urlString.trim()
  }
}
