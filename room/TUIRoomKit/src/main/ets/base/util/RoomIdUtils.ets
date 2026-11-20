const roomIDLength: number = 6

export function generateRoomID(length: number = roomIDLength): string {
  if (!Number.isInteger(length) || length <= 0 || length > 9) {
    throw new Error('Room ID length must be an integer from 1 to 9')
  }
  const min = Math.pow(10, length - 1)
  const max = Math.pow(10, length)
  return `${Math.floor(min + Math.random() * (max - min))}`
}
