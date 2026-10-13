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

/// Construction/access errors; allocation may also fail with OutOfMemory.
pub const BufferError = error{
    OutOfBounds,
    Misaligned,
    OutOfMemory,
};

/// Owns a fixed-length allocation. Call deinit exactly once when all views are
/// no longer needed. Keep this owner at a stable address while views reference it.
pub const ArrayBuffer = struct {
    /// Allocator used to allocate and release bytes.
    allocator: Allocator,
    /// Mutable backing storage; callers must preserve its allocation and length.
    bytes: []u8,
    /// Distinguishes `SharedArrayBuffer` from `ArrayBuffer` for the
    /// engine layer (prototype dispatch) -- storage-wise identical,
    /// since this library models neither's cross-agent semantics (see
    /// the module doc comment). Defaults false so every existing call
    /// site is unaffected.
    is_shared: bool = false,

    /// Allocates a new zero-initialized buffer of `byte_length` bytes
    /// (spec: ArrayBuffer contents start zeroed).
    pub fn init(allocator: Allocator, byte_length: usize) Allocator.Error!ArrayBuffer {
        const bytes = try allocator.alloc(u8, byte_length);
        @memset(bytes, 0);
        return .{ .allocator = allocator, .bytes = bytes };
    }

    /// Releases the allocation. Invalidates all views referencing this buffer.
    pub fn deinit(self: *ArrayBuffer) void {
        self.allocator.free(self.bytes);
    }

    /// Returns the allocation length in bytes.
    pub fn byteLength(self: *const ArrayBuffer) usize {
        return self.bytes.len;
    }

    /// Spec `ArrayBuffer.prototype.slice(start, end)`: a NEW buffer
    /// holding a COPY of `[start, end)` -- never aliases the source.
    /// Takes already-resolved, in-range byte offsets (`start <= end <=
    /// byteLength()`) -- negative-index clamping / ToIndex is a
    /// JS-coercion concern for downstream integration, not this layer.
    /// Returns OutOfBounds for an invalid range, or OutOfMemory on allocation failure.
    pub fn slice(self: *const ArrayBuffer, allocator: Allocator, start: usize, end: usize) BufferError!ArrayBuffer {
        if (start > end or end > self.bytes.len) return error.OutOfBounds;
        const out = try ArrayBuffer.init(allocator, end - start);
        @memcpy(out.bytes, self.bytes[start..end]);
        return out;
    }
};
