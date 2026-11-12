export const isEncoderSupported: () => boolean;
export const isDecoderSupported: () => boolean;
export const createEncoder: (bitRate: number, onPackets: (packets: ArrayBuffer[]) => void) => number;
export const createDecoder: (onChunk: (tag: number, pcm: ArrayBuffer, finished: boolean) => void) => number;
export const encode: (handle: number, pcm: ArrayBuffer) => void;
export const decode: (handle: number, packets: ArrayBuffer[], finished: boolean, tag: number) => void;
export const reset: (handle: number) => void;
export const release: (handle: number) => void;
