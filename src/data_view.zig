//! A byte-offset/length window into an `ArrayBuffer` with explicit
//! per-call endianness -- the storage/access primitive JS's `DataView`
//! is built on.
//!
//! `getInt8`/`getUint8`/`setInt8`/`setUint8` take NO endianness
//! argument (matches the real spec exactly: a single byte has no byte
//! order -- verified against real Node, `DataView.prototype.getInt8
//! .length === 1`, no littleEndian parameter at all). Every other kind
//! takes an explicit `little_endian: bool`, with NO default -- this is
//! a low-level library; the JS-visible default (littleEndian omitted
//! == big-endian) is a wiring-phase/coercion concern, not this layer's.

const std = @import("std");
const array_buffer = @import("array_buffer.zig");
const codec = @import("codec.zig");
const ArrayBuffer = array_buffer.ArrayBuffer;
/// Errors returned by view construction and checked numeric access.
pub const BufferError = array_buffer.BufferError;

/// A non-owning byte window. Keep the owner valid at a stable address while
/// using the view. Access offsets are relative to this window, in bytes.
/// Multi-byte access permits unaligned offsets and requires explicit byte order.
/// Public fields must preserve the bounds established by init.
/// Extreme usize offsets/lengths can overflow existing additive bounds checks;
/// see docs/node-buffer-parity.md for the known limitation.
pub const DataView = struct {
    /// Owner of the backing allocation.
    buffer: *ArrayBuffer,
    /// Starting byte offset in the backing buffer.
    byte_offset: usize,
    /// Length of this window in bytes.
    byte_length: usize,

    /// `byte_length` omitted (null) -> covers everything from
    /// `byte_offset` to the end of the buffer (spec: `new
    /// DataView(buffer, byteOffset)` with no length argument).
    /// Returns OutOfBounds when the requested window exceeds the backing buffer.
    pub fn init(buffer: *ArrayBuffer, byte_offset: usize, byte_length: ?usize) BufferError!DataView {
        const avail = buffer.byteLength();
        if (byte_offset > avail) return error.OutOfBounds;
        const len = byte_length orelse (avail - byte_offset);
        if (byte_offset + len > avail) return error.OutOfBounds;
        return .{ .buffer = buffer, .byte_offset = byte_offset, .byte_length = len };
    }

    fn window(self: DataView, offset: usize, n: usize) BufferError![]u8 {
        if (self.buffer.isDetached() or offset + n > self.byte_length) return error.OutOfBounds;
        const start = self.byte_offset + offset;
        if (start + n > self.buffer.bytes.len) return error.OutOfBounds;
        return self.buffer.bytes[start..];
    }

    fn endianOf(little: bool) std.lang.Endian {
        return if (little) .little else .big;
    }

    /// Reads a Int8 value at the byte offset; returns OutOfBounds if it exceeds the window.
    pub fn getInt8(self: DataView, offset: usize) BufferError!i8 {
        return codec.readNum(i8, try self.window(offset, 1), .big);
    }
    /// Reads a Uint8 value at the byte offset; returns OutOfBounds if it exceeds the window.
    pub fn getUint8(self: DataView, offset: usize) BufferError!u8 {
        return codec.readNum(u8, try self.window(offset, 1), .big);
    }
    /// Writes a Int8 value at the byte offset; returns OutOfBounds if it exceeds the window.
    pub fn setInt8(self: DataView, offset: usize, value: i8) BufferError!void {
        codec.writeNum(i8, try self.window(offset, 1), value, .big);
    }
    /// Writes a Uint8 value at the byte offset; returns OutOfBounds if it exceeds the window.
    pub fn setUint8(self: DataView, offset: usize, value: u8) BufferError!void {
        codec.writeNum(u8, try self.window(offset, 1), value, .big);
    }

    /// Reads a Int16 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn getInt16(self: DataView, offset: usize, little_endian: bool) BufferError!i16 {
        return codec.readNum(i16, try self.window(offset, 2), endianOf(little_endian));
    }
    /// Reads a Uint16 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn getUint16(self: DataView, offset: usize, little_endian: bool) BufferError!u16 {
        return codec.readNum(u16, try self.window(offset, 2), endianOf(little_endian));
    }
    /// Writes a Int16 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn setInt16(self: DataView, offset: usize, value: i16, little_endian: bool) BufferError!void {
        codec.writeNum(i16, try self.window(offset, 2), value, endianOf(little_endian));
    }
    /// Writes a Uint16 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn setUint16(self: DataView, offset: usize, value: u16, little_endian: bool) BufferError!void {
        codec.writeNum(u16, try self.window(offset, 2), value, endianOf(little_endian));
    }

    /// Reads a Int32 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn getInt32(self: DataView, offset: usize, little_endian: bool) BufferError!i32 {
        return codec.readNum(i32, try self.window(offset, 4), endianOf(little_endian));
    }
    /// Reads a Uint32 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn getUint32(self: DataView, offset: usize, little_endian: bool) BufferError!u32 {
        return codec.readNum(u32, try self.window(offset, 4), endianOf(little_endian));
    }
    /// Writes a Int32 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn setInt32(self: DataView, offset: usize, value: i32, little_endian: bool) BufferError!void {
        codec.writeNum(i32, try self.window(offset, 4), value, endianOf(little_endian));
    }
    /// Writes a Uint32 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn setUint32(self: DataView, offset: usize, value: u32, little_endian: bool) BufferError!void {
        codec.writeNum(u32, try self.window(offset, 4), value, endianOf(little_endian));
    }

    /// Reads a Float32 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn getFloat32(self: DataView, offset: usize, little_endian: bool) BufferError!f32 {
        return codec.readNum(f32, try self.window(offset, 4), endianOf(little_endian));
    }
    /// Writes a Float32 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn setFloat32(self: DataView, offset: usize, value: f32, little_endian: bool) BufferError!void {
        codec.writeNum(f32, try self.window(offset, 4), value, endianOf(little_endian));
    }

    /// Reads a Float64 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn getFloat64(self: DataView, offset: usize, little_endian: bool) BufferError!f64 {
        return codec.readNum(f64, try self.window(offset, 8), endianOf(little_endian));
    }
    /// Writes a Float64 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn setFloat64(self: DataView, offset: usize, value: f64, little_endian: bool) BufferError!void {
        codec.writeNum(f64, try self.window(offset, 8), value, endianOf(little_endian));
    }

    /// Reads a BigInt64 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn getBigInt64(self: DataView, offset: usize, little_endian: bool) BufferError!i64 {
        return codec.readNum(i64, try self.window(offset, 8), endianOf(little_endian));
    }
    /// Reads a BigUint64 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn getBigUint64(self: DataView, offset: usize, little_endian: bool) BufferError!u64 {
        return codec.readNum(u64, try self.window(offset, 8), endianOf(little_endian));
    }
    /// Writes a BigInt64 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn setBigInt64(self: DataView, offset: usize, value: i64, little_endian: bool) BufferError!void {
        codec.writeNum(i64, try self.window(offset, 8), value, endianOf(little_endian));
    }
    /// Writes a BigUint64 value at the byte offset; returns OutOfBounds if it exceeds the window. Uses little-endian order when little_endian is true, big-endian otherwise.
    pub fn setBigUint64(self: DataView, offset: usize, value: u64, little_endian: bool) BufferError!void {
        codec.writeNum(u64, try self.window(offset, 8), value, endianOf(little_endian));
    }
};
