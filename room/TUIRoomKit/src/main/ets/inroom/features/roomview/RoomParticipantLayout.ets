export interface RoomStageSize {
  width: number
  height: number
}

export interface RoomGridMetrics {
  columns: number
  rows: number
  contentInset: number
  itemGap: number
  itemWidth: number
  itemHeight: number
}

export interface RoomItemRect {
  x: number
  y: number
  width: number
  height: number
}

export enum RoomFloatingSide {
  LEFT,
  RIGHT,
}

export interface RoomFloatingPosition {
  side: RoomFloatingSide
  verticalFraction: number
}

export class RoomParticipantLayout {
  static readonly pageCapacity: number = 6
  static readonly itemAspectRatio: number = 9.0 / 16.0

  static contentInset(size: RoomStageSize): number {
    return Math.min(8, Math.min(size.width, size.height) / 8)
  }

  static gridMetrics(count: number, multiplePages: boolean, size: RoomStageSize): RoomGridMetrics {
    const contentInset = RoomParticipantLayout.contentInset(size)
    const itemGap = Math.min(4, Math.min(size.width, size.height) / 8)
    const columns = multiplePages ? 3 : (count <= 1 ? 1 : (count === 2 || count <= 4 ? 2 : 3))
    const rows = multiplePages || count > 2 ? 2 : 1
    const widthPerColumn = (size.width - contentInset * 2 - itemGap * (columns - 1)) / columns
    const heightPerRow = (size.height - contentInset * 2 - itemGap * (rows - 1)) / rows
    const single = count === 1 && !multiplePages
    const itemWidth = single ? Math.max(widthPerColumn, 0) :
      Math.max(Math.min(widthPerColumn, heightPerRow * RoomParticipantLayout.itemAspectRatio), 0)
    return {
      columns,
      rows,
      contentInset,
      itemGap,
      itemWidth,
      itemHeight: single ? Math.max(heightPerRow, 0) : itemWidth / RoomParticipantLayout.itemAspectRatio,
    }
  }

  static participantRects(count: number, multiplePages: boolean, size: RoomStageSize): RoomItemRect[] {
    if (count <= 0) {
      return []
    }
    const metrics = RoomParticipantLayout.gridMetrics(count, multiplePages, size)
    if (count === 1 && !multiplePages) {
      return [{ x: metrics.contentInset, y: metrics.contentInset,
        width: metrics.itemWidth, height: metrics.itemHeight }]
    }
    const gridTop = (size.height - metrics.itemHeight * metrics.rows - metrics.itemGap * (metrics.rows - 1)) / 2
    const rects: RoomItemRect[] = []
    for (let index = 0; index < count; index++) {
      const rowIndex = Math.floor(index / metrics.columns)
      const columnIndex = index % metrics.columns
      const itemsInRow = multiplePages ? metrics.columns : Math.min(metrics.columns, count - rowIndex * metrics.columns)
      const rowWidth = metrics.itemWidth * itemsInRow + metrics.itemGap * (itemsInRow - 1)
      const rowLeft = (size.width - rowWidth) / 2
      const rect: RoomItemRect = {
        x: rowLeft + columnIndex * (metrics.itemWidth + metrics.itemGap),
        y: gridTop + rowIndex * (metrics.itemHeight + metrics.itemGap),
        width: metrics.itemWidth,
        height: metrics.itemHeight,
      }
      rects.push(rect)
    }
    return rects
  }

  static floatingInset(size: RoomStageSize): number {
    return Math.min(8, Math.min(size.width, size.height) / 4)
  }

  static floatingBounds(size: RoomStageSize, position: RoomFloatingPosition): RoomItemRect {
    const inset = RoomParticipantLayout.floatingInset(size)
    const preferredWidth = Math.min(size.width * 0.24, 120)
    const widthFittingHeight = (size.height - inset * 2) * RoomParticipantLayout.itemAspectRatio
    const itemWidth = Math.min(preferredWidth, widthFittingHeight)
    const itemHeight = itemWidth / RoomParticipantLayout.itemAspectRatio
    const minTop = inset
    const maxTop = size.height - inset - itemHeight
    const fraction = Math.min(Math.max(position.verticalFraction, 0), 1)
    const top = maxTop <= minTop ? minTop : minTop + (maxTop - minTop) * fraction
    const x = position.side === RoomFloatingSide.LEFT ? inset : size.width - inset - itemWidth
    return { x, y: top, width: itemWidth, height: itemHeight }
  }

  static clampFloatingPosition(x: number, y: number, rect: RoomItemRect, size: RoomStageSize): RoomItemRect {
    const inset = RoomParticipantLayout.floatingInset(size)
    const maxLeft = Math.max(size.width - rect.width - inset, inset)
    const maxTop = Math.max(size.height - rect.height - inset, inset)
    return {
      x: Math.min(Math.max(x, inset), maxLeft),
      y: Math.min(Math.max(y, inset), maxTop),
      width: rect.width,
      height: rect.height,
    }
  }

  static settledFloatingPosition(rect: RoomItemRect, size: RoomStageSize): RoomFloatingPosition {
    const inset = RoomParticipantLayout.floatingInset(size)
    const maxTop = Math.max(size.height - rect.height - inset, inset)
    const clampedTop = Math.min(Math.max(rect.y, inset), maxTop)
    return {
      side: rect.x + rect.width / 2 < size.width / 2 ? RoomFloatingSide.LEFT : RoomFloatingSide.RIGHT,
      verticalFraction: maxTop > inset ? (clampedTop - inset) / (maxTop - inset) : 0,
    }
  }
}
