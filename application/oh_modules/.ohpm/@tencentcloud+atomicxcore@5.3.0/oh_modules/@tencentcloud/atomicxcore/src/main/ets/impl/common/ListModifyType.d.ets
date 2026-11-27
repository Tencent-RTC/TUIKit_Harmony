/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   ListModifyType @ AtomicXCore
 * Function: List modification type used by `<ModuleName>.stateChanged` passive events.
 *
 * When the engine pushes a list-type state change, the payload carries a
 * ListModifyType value to indicate how the local list should be merged.
 *
 * | Value | Meaning |
 * |-------|---------|
 * | `none` | No structural change (placeholder) |
 * | `full` | Full replacement — overwrite the local list entirely |
 * | `add` | Incremental add — append new items, deduplicate by key |
 * | `remove` | Incremental remove — filter out items matching the payload keys |
 * | `replace` | Incremental replace — replace items matching the payload keys |
 */
export declare enum ListModifyType {
    none = 0,
    full = 1,
    add = 2,
    remove = 3,
    replace = 4
}
