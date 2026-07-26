//! A fixed-length, zero-initialized byte buffer -- the storage layer
//! JS's `ArrayBuffer` is built on. Part of the general-purpose
//! `z-buffer` sibling library (no `JSValue`, no engine coupling).
//!
//! Scope: fixed-length only. Resizable ArrayBuffer (`maxByteLength`,
//! `.resize()`) and `.transfer()`/`.transferToFixedLength()` are real
//! ownership/aliasing features (a transferred buffer detaches, live
//! views must observe it) -- deliberately out of scope for v1, see the
//! repo README.

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const BufferError = error{
    OutOfBounds,
    Misaligned,
    OutOfMemory,
};

pub const ArrayBuffer = struct {
    allocator: Allocator,
    bytes: []u8,

    /// Allocates a new zero-initialized buffer of `byte_length` bytes
    /// (spec: ArrayBuffer contents start zeroed).
    pub fn init(allocator: Allocator, byte_length: usize) Allocator.Error!ArrayBuffer {
        const bytes = try allocator.alloc(u8, byte_length);
        @memset(bytes, 0);
        return .{ .allocator = allocator, .bytes = bytes };
    }

    pub fn deinit(self: *ArrayBuffer) void {
        self.allocator.free(self.bytes);
    }

    pub fn byteLength(self: *const ArrayBuffer) usize {
        return self.bytes.len;
    }

    /// Spec `ArrayBuffer.prototype.slice(start, end)`: a NEW buffer
    /// holding a COPY of `[start, end)` -- never aliases the source.
    /// Takes already-resolved, in-range byte offsets (`start <= end <=
    /// byteLength()`) -- negative-index clamping / ToIndex is a
    /// JS-coercion concern for the future wiring phase, not this layer.
    pub fn slice(self: *const ArrayBuffer, allocator: Allocator, start: usize, end: usize) BufferError!ArrayBuffer {
        if (start > end or end > self.bytes.len) return error.OutOfBounds;
        const out = try ArrayBuffer.init(allocator, end - start);
        @memcpy(out.bytes, self.bytes[start..end]);
        return out;
    }
};
