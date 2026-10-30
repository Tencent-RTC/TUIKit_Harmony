export class DebouncedClick {
  private lastClickTimes: Map<string, number> = new Map()

  perform(control: string, action: () => void, interval: number = 1): void {
    const now = Date.now() / 1000
    const lastClick = this.lastClickTimes.get(control)
    if (lastClick !== undefined && now - lastClick < interval) {
      return
    }
    this.lastClickTimes.set(control, now)
    action()
  }
}
