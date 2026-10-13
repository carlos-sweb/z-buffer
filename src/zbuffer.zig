//! z-buffer: a general-purpose, fixed-length byte buffer with typed and
//! endian-aware views -- ArrayBuffer/DataView/TypedArray's storage
//! layer, part of the [z-*](https://github.com/carlos-sweb) sibling
//! micro-library ecosystem. Nothing JS-specific lives here (no
//! `JSValue`, no engine coupling): wiring this into the JS engine
//! (a `z-value` JSValue variant, `z-interpreter` constructors/
//! prototype methods/GC) is maintained downstream.
//!
//! Scope: see README.md for the full supported/deferred list. In
//! short: fixed-length `ArrayBuffer` only (no resizable ArrayBuffer,
//! no `.transfer()`), no Atomics/SharedArrayBuffer, no JS-value
//! coercion (ToIndex/ToUint8Clamp/etc. -- callers pass already-
//! resolved Zig values and indices).

const array_buffer = @import("array_buffer.zig");
const data_view = @import("data_view.zig");
const typed_array = @import("typed_array.zig");

/// Errors returned by checked buffer and view operations.
pub const BufferError = array_buffer.BufferError;
/// Owning, fixed-length, zero-initialized byte storage.
pub const ArrayBuffer = array_buffer.ArrayBuffer;
/// A non-owning byte window with explicit endianness.
pub const DataView = data_view.DataView;
/// Creates a non-owning native-endian element view type.
pub const TypedArrayView = typed_array.TypedArrayView;

/// The 10 distinct storage kinds JS's TypedArray family needs.
/// `Uint8ClampedArray` is NOT listed separately -- it IS `Uint8Array`
/// here (`TypedArrayView(u8)`); see typed_array.zig's doc comment.
/// Native-endian view of signed 8-bit integers.
pub const Int8Array = TypedArrayView(i8);
/// Native-endian view of unsigned 8-bit integers.
pub const Uint8Array = TypedArrayView(u8);
/// Native-endian view of signed 16-bit integers.
pub const Int16Array = TypedArrayView(i16);
/// Native-endian view of unsigned 16-bit integers.
pub const Uint16Array = TypedArrayView(u16);
/// Native-endian view of signed 32-bit integers.
pub const Int32Array = TypedArrayView(i32);
/// Native-endian view of unsigned 32-bit integers.
pub const Uint32Array = TypedArrayView(u32);
/// Native-endian view of 32-bit floating-point values.
pub const Float32Array = TypedArrayView(f32);
/// Native-endian view of 64-bit floating-point values.
pub const Float64Array = TypedArrayView(f64);
/// Native-endian view of signed 64-bit integers.
pub const BigInt64Array = TypedArrayView(i64);
/// Native-endian view of unsigned 64-bit integers.
pub const BigUint64Array = TypedArrayView(u64);

test {
    _ = @import("array_buffer.zig");
    _ = @import("codec.zig");
    _ = @import("data_view.zig");
    _ = @import("typed_array.zig");
}
