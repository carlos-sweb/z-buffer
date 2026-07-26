//! Byte-pattern expectations below were captured from real Node.js
//! (`new DataView(...).setXxx(...)` followed by reading the raw bytes)
//! during planning -- see the plan's Design section. Any drift here is
//! a real bug, not a rounding choice.
const std = @import("std");
const zbuffer = @import("zbuffer");
const ArrayBuffer = zbuffer.ArrayBuffer;
const DataView = zbuffer.DataView;

fn newBuf(n: usize) !ArrayBuffer {
    return ArrayBuffer.init(std.testing.allocator, n);
}

test "Int8/Uint8 take no endianness argument and roundtrip" {
    var buf = try newBuf(2);
    defer buf.deinit();
    const dv = try DataView.init(&buf, 0, null);

    try dv.setInt8(0, -1);
    try std.testing.expectEqual(@as(u8, 0xFF), buf.bytes[0]);
    try std.testing.expectEqual(@as(i8, -1), try dv.getInt8(0));

    try dv.setUint8(1, 200);
    try std.testing.expectEqual(@as(u8, 200), buf.bytes[1]);
    try std.testing.expectEqual(@as(u8, 200), try dv.getUint8(1));
}

test "Int16/Uint16 match real Node byte patterns, both endiannesses" {
    var buf = try newBuf(2);
    defer buf.deinit();
    const dv = try DataView.init(&buf, 0, null);

    try dv.setInt16(0, -3, false);
    try std.testing.expectEqualSlices(u8, &.{ 255, 253 }, buf.bytes);
    try std.testing.expectEqual(@as(i16, -3), try dv.getInt16(0, false));

    try dv.setInt16(0, -3, true);
    try std.testing.expectEqualSlices(u8, &.{ 253, 255 }, buf.bytes);
    try std.testing.expectEqual(@as(i16, -3), try dv.getInt16(0, true));

    try dv.setUint16(0, 65535, false);
    try std.testing.expectEqualSlices(u8, &.{ 255, 255 }, buf.bytes);
}

test "Int32/Uint32 match real Node byte patterns, both endiannesses" {
    var buf = try newBuf(4);
    defer buf.deinit();
    const dv = try DataView.init(&buf, 0, null);

    try dv.setInt32(0, -2147483648, false);
    try std.testing.expectEqualSlices(u8, &.{ 128, 0, 0, 0 }, buf.bytes);
    try std.testing.expectEqual(@as(i32, -2147483648), try dv.getInt32(0, false));

    try dv.setInt32(0, -2147483648, true);
    try std.testing.expectEqualSlices(u8, &.{ 0, 0, 0, 128 }, buf.bytes);

    try dv.setUint32(0, 4294967295, false);
    try std.testing.expectEqualSlices(u8, &.{ 255, 255, 255, 255 }, buf.bytes);
}

test "Float32 matches real Node byte patterns, both endiannesses" {
    var buf = try newBuf(4);
    defer buf.deinit();
    const dv = try DataView.init(&buf, 0, null);

    try dv.setFloat32(0, 3.14, false);
    try std.testing.expectEqualSlices(u8, &.{ 64, 72, 245, 195 }, buf.bytes);
    try std.testing.expectApproxEqAbs(@as(f32, 3.14), try dv.getFloat32(0, false), 0.0001);

    try dv.setFloat32(0, 3.14, true);
    try std.testing.expectEqualSlices(u8, &.{ 195, 245, 72, 64 }, buf.bytes);

    try dv.setFloat32(0, std.math.inf(f32), false);
    try std.testing.expectEqualSlices(u8, &.{ 127, 128, 0, 0 }, buf.bytes);

    try dv.setFloat32(0, -std.math.inf(f32), false);
    try std.testing.expectEqualSlices(u8, &.{ 255, 128, 0, 0 }, buf.bytes);

    try dv.setFloat32(0, std.math.nan(f32), false);
    try std.testing.expect(std.math.isNan(try dv.getFloat32(0, false)));
}

test "Float64 matches real Node byte patterns, both endiannesses" {
    var buf = try newBuf(8);
    defer buf.deinit();
    const dv = try DataView.init(&buf, 0, null);

    try dv.setFloat64(0, 3.14, false);
    try std.testing.expectEqualSlices(u8, &.{ 64, 9, 30, 184, 81, 235, 133, 31 }, buf.bytes);
    try std.testing.expectApproxEqAbs(@as(f64, 3.14), try dv.getFloat64(0, false), 0.00001);

    try dv.setFloat64(0, 3.14, true);
    try std.testing.expectEqualSlices(u8, &.{ 31, 133, 235, 81, 184, 30, 9, 64 }, buf.bytes);

    try dv.setFloat64(0, std.math.nan(f64), false);
    try std.testing.expect(std.math.isNan(try dv.getFloat64(0, false)));
}

test "BigInt64/BigUint64 match real Node byte patterns" {
    var buf = try newBuf(8);
    defer buf.deinit();
    const dv = try DataView.init(&buf, 0, null);

    try dv.setBigInt64(0, -1, false);
    try std.testing.expectEqualSlices(u8, &.{ 255, 255, 255, 255, 255, 255, 255, 255 }, buf.bytes);
    try dv.setBigInt64(0, -1, true);
    try std.testing.expectEqualSlices(u8, &.{ 255, 255, 255, 255, 255, 255, 255, 255 }, buf.bytes);

    try dv.setBigInt64(0, std.math.maxInt(i64), false);
    try std.testing.expectEqualSlices(u8, &.{ 127, 255, 255, 255, 255, 255, 255, 255 }, buf.bytes);
    try std.testing.expectEqual(@as(i64, std.math.maxInt(i64)), try dv.getBigInt64(0, false));

    try dv.setBigUint64(0, std.math.maxInt(u64), false);
    try std.testing.expectEqualSlices(u8, &.{ 255, 255, 255, 255, 255, 255, 255, 255 }, buf.bytes);
    try std.testing.expectEqual(@as(u64, std.math.maxInt(u64)), try dv.getBigUint64(0, false));
}

test "a DataView window with an explicit byte_offset/byte_length restricts access" {
    var buf = try newBuf(8);
    defer buf.deinit();
    const dv = try DataView.init(&buf, 2, 4); // bytes [2,6)

    try dv.setInt32(0, 0x11223344, false);
    try std.testing.expectEqualSlices(u8, &.{ 0x11, 0x22, 0x33, 0x44 }, buf.bytes[2..6]);
    try std.testing.expectEqual(@as(u8, 0), buf.bytes[0]); // untouched
    try std.testing.expectEqual(@as(u8, 0), buf.bytes[6]); // untouched

    try std.testing.expectError(error.OutOfBounds, dv.getInt32(1, false)); // 1+4 > byte_length(4)
}

test "init rejects an out-of-range window" {
    var buf = try newBuf(4);
    defer buf.deinit();
    try std.testing.expectError(error.OutOfBounds, DataView.init(&buf, 2, 4));
    try std.testing.expectError(error.OutOfBounds, DataView.init(&buf, 5, null));
}
