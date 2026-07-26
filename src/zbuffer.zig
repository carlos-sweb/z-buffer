//! z-buffer: a general-purpose, fixed-length byte buffer with typed and
//! endian-aware views -- ArrayBuffer/DataView/TypedArray's storage
//! layer, part of the [z-*](https://github.com/carlos-sweb) sibling
//! micro-library ecosystem. Nothing JS-specific lives here (no
//! `JSValue`, no engine coupling): wiring this into the JS engine
//! (a `z-value` JSValue variant, `z-interpreter` constructors/
//! prototype methods/GC) is a separate, not-yet-started phase.
//!
//! Scope: see README.md for the full supported/deferred list. In
//! short: fixed-length `ArrayBuffer` only (no resizable ArrayBuffer,
//! no `.transfer()`), no Atomics/SharedArrayBuffer, no JS-value
//! coercion (ToIndex/ToUint8Clamp/etc. -- callers pass already-
//! resolved Zig values and indices).

const array_buffer = @import("array_buffer.zig");
const data_view = @import("data_view.zig");
const typed_array = @import("typed_array.zig");

pub const BufferError = array_buffer.BufferError;
pub const ArrayBuffer = array_buffer.ArrayBuffer;
pub const DataView = data_view.DataView;
pub const TypedArrayView = typed_array.TypedArrayView;

/// The 9 distinct storage kinds JS's TypedArray family needs.
/// `Uint8ClampedArray` is NOT listed separately -- it IS `Uint8Array`
/// here (`TypedArrayView(u8)`); see typed_array.zig's doc comment.
pub const Int8Array = TypedArrayView(i8);
pub const Uint8Array = TypedArrayView(u8);
pub const Int16Array = TypedArrayView(i16);
pub const Uint16Array = TypedArrayView(u16);
pub const Int32Array = TypedArrayView(i32);
pub const Uint32Array = TypedArrayView(u32);
pub const Float32Array = TypedArrayView(f32);
pub const Float64Array = TypedArrayView(f64);
pub const BigInt64Array = TypedArrayView(i64);
pub const BigUint64Array = TypedArrayView(u64);

test {
    _ = @import("array_buffer.zig");
    _ = @import("codec.zig");
    _ = @import("data_view.zig");
    _ = @import("typed_array.zig");
}
