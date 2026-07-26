const std = @import("std");
const zbuffer = @import("zbuffer");
const ArrayBuffer = zbuffer.ArrayBuffer;
const DataView = zbuffer.DataView;

fn newBuf(n: usize) !ArrayBuffer {
    return ArrayBuffer.init(std.testing.allocator, n);
}

test "Int32Array roundtrips and covers the full buffer when len is omitted" {
    var buf = try newBuf(12);
    defer buf.deinit();
    const view = try zbuffer.Int32Array.init(&buf, 0, null);
    try std.testing.expectEqual(@as(usize, 3), view.len);

    try view.set(0, -1);
    try view.set(1, 42);
    try view.set(2, std.math.minInt(i32));
    try std.testing.expectEqual(@as(i32, -1), try view.get(0));
    try std.testing.expectEqual(@as(i32, 42), try view.get(1));
    try std.testing.expectEqual(@as(i32, std.math.minInt(i32)), try view.get(2));
}

test "every integer element kind roundtrips its own type's min/max" {
    const kinds = .{
        .{ zbuffer.Int8Array, i8 },       .{ zbuffer.Uint8Array, u8 },
        .{ zbuffer.Int16Array, i16 },     .{ zbuffer.Uint16Array, u16 },
        .{ zbuffer.Int32Array, i32 },     .{ zbuffer.Uint32Array, u32 },
        .{ zbuffer.BigInt64Array, i64 },  .{ zbuffer.BigUint64Array, u64 },
    };
    inline for (kinds) |pair| {
        const Kind = pair[0];
        const T = pair[1];
        var buf = try newBuf(Kind.elem_size);
        defer buf.deinit();
        const view = try Kind.init(&buf, 0, 1);

        try view.set(0, std.math.minInt(T));
        try std.testing.expectEqual(@as(T, std.math.minInt(T)), try view.get(0));
        try view.set(0, std.math.maxInt(T));
        try std.testing.expectEqual(@as(T, std.math.maxInt(T)), try view.get(0));
    }
}

test "Float32Array/Float64Array roundtrip" {
    var buf = try newBuf(8);
    defer buf.deinit();

    const f32v = try zbuffer.Float32Array.init(&buf, 0, 2);
    try f32v.set(0, 3.14);
    try f32v.set(1, -1.5);
    try std.testing.expectApproxEqAbs(@as(f32, 3.14), try f32v.get(0), 0.0001);
    try std.testing.expectEqual(@as(f32, -1.5), try f32v.get(1));

    const f64v = try zbuffer.Float64Array.init(&buf, 0, 1);
    try f64v.set(0, 3.14159265358979);
    try std.testing.expectApproxEqAbs(@as(f64, 3.14159265358979), try f64v.get(0), 1e-12);
}

test "byte_offset not a multiple of the element size is Misaligned" {
    var buf = try newBuf(8);
    defer buf.deinit();
    try std.testing.expectError(error.Misaligned, zbuffer.Int32Array.init(&buf, 1, null));
    try std.testing.expectError(error.Misaligned, zbuffer.Int16Array.init(&buf, 3, null));
    // aligned offsets are fine
    _ = try zbuffer.Int32Array.init(&buf, 4, null);
}

test "out-of-range length/index is OutOfBounds" {
    var buf = try newBuf(8);
    defer buf.deinit();
    try std.testing.expectError(error.OutOfBounds, zbuffer.Int32Array.init(&buf, 0, 3)); // 3*4=12 > 8
    const view = try zbuffer.Int32Array.init(&buf, 0, 2);
    try std.testing.expectError(error.OutOfBounds, view.get(2));
    try std.testing.expectError(error.OutOfBounds, view.set(2, 1));
}

test "Uint8ClampedArray IS Uint8Array (documented non-distinction)" {
    try std.testing.expectEqual(zbuffer.Uint8Array, zbuffer.TypedArrayView(u8));
}

test "TypedArrayView (native endian) and DataView (explicit native endian) agree on the same buffer" {
    var buf = try newBuf(4);
    defer buf.deinit();
    const view = try zbuffer.Int32Array.init(&buf, 0, 1);
    try view.set(0, 0x11223344);

    const dv = try DataView.init(&buf, 0, null);
    const is_little = @import("builtin").cpu.arch.endian() == .little;
    const via_dv = try dv.getInt32(0, is_little);
    try std.testing.expectEqual(@as(i32, 0x11223344), via_dv);
}

test "two TypedArray views over disjoint windows of the same buffer don't alias" {
    var buf = try newBuf(8);
    defer buf.deinit();
    const lo = try zbuffer.Int32Array.init(&buf, 0, 1);
    const hi = try zbuffer.Int32Array.init(&buf, 4, 1);

    try lo.set(0, 111);
    try hi.set(0, 222);
    try std.testing.expectEqual(@as(i32, 111), try lo.get(0));
    try std.testing.expectEqual(@as(i32, 222), try hi.get(0));
}
