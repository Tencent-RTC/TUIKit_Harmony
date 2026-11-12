export class PreRollBuffer {
  private readonly capacity: number;
  private packets: ArrayBuffer[] = [];

  constructor(capacity: number) {
    this.capacity = Math.max(1, capacity);
  }

  get size(): number {
    return this.packets.length;
  }

  append(packet: ArrayBuffer): void {
    while (this.packets.length >= this.capacity) {
      this.packets.shift();
    }
    this.packets.push(packet);
  }

  appendFromSpeechOnset(packet: ArrayBuffer, speechAccumulationMs: number): void {
    if (speechAccumulationMs <= 0) {
      this.packets = [];
    } else {
      this.append(packet);
    }
  }

  clear(): void {
    this.packets = [];
  }

  drain(): ArrayBuffer[] {
    const drained = this.packets;
    this.packets = [];
    return drained;
  }
}
