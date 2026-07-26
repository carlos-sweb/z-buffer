//! Shared byte<->number codec used by both `DataView` (explicit
//! endianness per call) and `TypedArrayView` (fixed native endianness)
//! -- kept in one place so the two element-access paths can never
//! silently diverge from each other.
//!
//! Deliberately goes through `std.mem.readInt`/`writeInt` rather than
//! any `@ptrCast`/`@alignCast` to `*T`: callers are only required to
//! guarantee the byte OFFSET is a multiple of the element size (real
//! spec requirement, enforced by `ArrayBuffer`'s callers), never that
//! the underlying allocation itself is over-aligned -- this codec makes
//! that guarantee unnecessary.
const std = @import("std");

/// Callers must pass `bytes.len >= @sizeOf(T)`; this is an internal
/// helper, bounds are the public API's (DataView/TypedArrayView)
/// responsibility, already checked once at that boundary.
pub fn readNum(comptime T: type, bytes: []const u8, endian: std.builtin.Endian) T {
    return switch (@typeInfo(T)) {
        .int => std.mem.readInt(T, bytes[0..@sizeOf(T)], endian),
        .float => |f| @bitCast(std.mem.readInt(std.meta.Int(.unsigned, f.bits), bytes[0..@sizeOf(T)], endian)),
        else => @compileError("readNum: unsupported type " ++ @typeName(T)),
    };
}

/// Same bounds contract as `readNum`.
pub fn writeNum(comptime T: type, bytes: []u8, value: T, endian: std.builtin.Endian) void {
    switch (@typeInfo(T)) {
        .int => std.mem.writeInt(T, bytes[0..@sizeOf(T)], value, endian),
        .float => |f| {
            const Bits = std.meta.Int(.unsigned, f.bits);
            const bits: Bits = @bitCast(value);
            std.mem.writeInt(Bits, bytes[0..@sizeOf(T)], bits, endian);
        },
        else => @compileError("writeNum: unsupported type " ++ @typeName(T)),
    }
}

pub const native_endian = @import("builtin").cpu.arch.endian();
