// Public API entry of @tencentcloud/tuicallkit.
// All exports are listed here. Internal implementation under src/main/ets/** is not exposed.

export { TUICallKit } from './src/main/ets/TUICallKit';

// Re-export call types from atomicxcore so app developers do not need to import twice.
export { CallMediaType, CallParams, CloudRecordPolicy } from '@tencentcloud/atomicxcore';

