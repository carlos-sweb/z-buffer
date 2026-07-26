const std = @import("std");
const zbuffer = @import("zbuffer");
const ArrayBuffer = zbuffer.ArrayBuffer;

test "init zero-fills and reports byteLength" {
    var buf = try ArrayBuffer.init(std.testing.allocator, 8);
    defer buf.deinit();
    try std.testing.expectEqual(@as(usize, 8), buf.byteLength());
    for (buf.bytes) |b| try std.testing.expectEqual(@as(u8, 0), b);
}

test "zero-length buffer is valid" {
    var buf = try ArrayBuffer.init(std.testing.allocator, 0);
    defer buf.deinit();
    try std.testing.expectEqual(@as(usize, 0), buf.byteLength());
}

test "slice copies and does not alias the source" {
    var buf = try ArrayBuffer.init(std.testing.allocator, 4);
    defer buf.deinit();
    buf.bytes[0] = 0xAA;
    buf.bytes[1] = 0xBB;

    var s = try buf.slice(std.testing.allocator, 0, 2);
    defer s.deinit();
    try std.testing.expectEqual(@as(usize, 2), s.byteLength());
    try std.testing.expectEqual(@as(u8, 0xAA), s.bytes[0]);

    buf.bytes[0] = 0xFF; // mutate the source after slicing
    try std.testing.expectEqual(@as(u8, 0xAA), s.bytes[0]); // slice unaffected
}

test "slice of the middle" {
    var buf = try ArrayBuffer.init(std.testing.allocator, 4);
    defer buf.deinit();
    buf.bytes[0] = 1;
    buf.bytes[1] = 2;
    buf.bytes[2] = 3;
    buf.bytes[3] = 4;

    var s = try buf.slice(std.testing.allocator, 1, 3);
    defer s.deinit();
    try std.testing.expectEqualSlices(u8, &.{ 2, 3 }, s.bytes);
}

test "slice rejects out-of-bounds and inverted ranges" {
    var buf = try ArrayBuffer.init(std.testing.allocator, 4);
    defer buf.deinit();
    try std.testing.expectError(error.OutOfBounds, buf.slice(std.testing.allocator, 0, 5));
    try std.testing.expectError(error.OutOfBounds, buf.slice(std.testing.allocator, 3, 1));
}
