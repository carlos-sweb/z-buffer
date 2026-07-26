//! Generic native-endian element view over an `ArrayBuffer` -- the
//! storage/access primitive JS's TypedArray family (Int8Array ..
//! Float64Array, BigInt64Array/BigUint64Array) is built on. See
//! `zbuffer.zig` for the concrete instantiations.
//!
//! `Uint8ClampedArray` has NO separate type here -- it is the exact
//! same storage as `Uint8Array` (`TypedArrayView(u8)`). The
//! clamped-on-WRITE coercion real JS applies (`ToUint8Clamp`, e.g.
//! `arr[0] = 300` becomes 255, `-10` becomes 0, round-half-to-even at
//! the .5 boundary) is a JS-VALUE-conversion concern -- it only matters
//! when converting an arbitrary JS Number into a byte, which happens
//! BEFORE a `set()` call ever reaches this layer. Deliberately not
//! distinguished here; see the repo README.

const std = @import("std");
const array_buffer = @import("array_buffer.zig");
const codec = @import("codec.zig");
const ArrayBuffer = array_buffer.ArrayBuffer;
pub const BufferError = array_buffer.BufferError;

pub fn TypedArrayView(comptime T: type) type {
    return struct {
        buffer: *ArrayBuffer,
        byte_offset: usize,
        len: usize, // element count

        const Self = @This();
        pub const elem_size = @sizeOf(T);

        /// `len` omitted (null) -> covers every whole element from
        /// `byte_offset` to the end of the buffer (spec: `new
        /// Int32Array(buffer, byteOffset)` with no length argument) --
        /// but the remaining bytes must divide EXACTLY into whole
        /// elements; a trailing partial element is `error.OutOfBounds`
        /// (real spec: `new Int32Array(new ArrayBuffer(6))` is a
        /// RangeError, not a silently-truncated 1-element view -- a
        /// truncating auto-length would silently drop trailing bytes
        /// for ANY caller, not just a JS-specific rule). Real spec
        /// RangeError if `byte_offset` isn't a multiple of the element
        /// size -- `error.Misaligned` here.
        pub fn init(buffer: *ArrayBuffer, byte_offset: usize, len: ?usize) BufferError!Self {
            if (byte_offset % elem_size != 0) return error.Misaligned;
            const avail = buffer.byteLength();
            if (byte_offset > avail) return error.OutOfBounds;
            const remaining_bytes = avail - byte_offset;
            const n = len orelse blk: {
                if (remaining_bytes % elem_size != 0) return error.OutOfBounds;
                break :blk remaining_bytes / elem_size;
            };
            if (n > remaining_bytes / elem_size) return error.OutOfBounds;
            return .{ .buffer = buffer, .byte_offset = byte_offset, .len = n };
        }

        pub fn byteLength(self: Self) usize {
            return self.len * elem_size;
        }

        pub fn get(self: Self, index: usize) BufferError!T {
            if (index >= self.len) return error.OutOfBounds;
            const off = self.byte_offset + index * elem_size;
            return codec.readNum(T, self.buffer.bytes[off..], codec.native_endian);
        }

        pub fn set(self: Self, index: usize, value: T) BufferError!void {
            if (index >= self.len) return error.OutOfBounds;
            const off = self.byte_offset + index * elem_size;
            codec.writeNum(T, self.buffer.bytes[off..], value, codec.native_endian);
        }
    };
}
