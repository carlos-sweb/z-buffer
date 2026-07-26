# Z-BUFFER

[![Zig Version](https://img.shields.io/badge/zig-0.16-orange.svg)](https://ziglang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A general-purpose, fixed-length byte buffer with typed and endian-aware views — part of the [z-*](https://github.com/carlos-sweb) micro-library ecosystem. Nothing JS-specific lives here (no `JSValue`, no engine coupling): a plain sibling library, reusable anywhere ArrayBuffer/DataView/TypedArray-shaped storage is useful. Wiring this into the z-* JS engine (a `z-value` JSValue variant, `z-interpreter` constructors/prototype methods/GC) is a separate, not-yet-started phase.

## Scope

**Supported:**
- `ArrayBuffer` — fixed-length, zero-initialized byte storage. `byteLength()`, `slice(allocator, start, end)` (a NEW buffer holding a copy, never aliases the source — matches real `ArrayBuffer.prototype.slice`).
- `DataView` — a byte-offset/length window into an `ArrayBuffer`, explicit per-call endianness. `getInt8`/`getUint8`/`setInt8`/`setUint8` take **no** endianness argument (matches the real spec exactly — a single byte has no byte order). Every other kind (`Int16`/`Uint16`/`Int32`/`Uint32`/`Float32`/`Float64`/`BigInt64`/`BigUint64`) takes an explicit `little_endian: bool`, with no default.
- `TypedArrayView(comptime T: type)` — a generic, **native-endian** element view over an `ArrayBuffer`. Instantiated for all 9 distinct storage kinds real JS needs: `Int8Array`/`Uint8Array`/`Int16Array`/`Uint16Array`/`Int32Array`/`Uint32Array`/`Float32Array`/`Float64Array`/`BigInt64Array`/`BigUint64Array` (all exported as aliases from `zbuffer.zig`). `Uint8ClampedArray` is deliberately **not** a separate type — it's the exact same storage as `Uint8Array` (see "What's deliberately not here" below).
- Bounds/alignment checking throughout: `BufferError{ OutOfBounds, Misaligned, OutOfMemory }`. TypedArray construction enforces `byte_offset % @sizeOf(T) == 0` (real spec: RangeError otherwise) as `error.Misaligned`.

**What's deliberately not here** (documented gaps, not oversights):
- **Resizable ArrayBuffer** (`maxByteLength`, `.resize()`) and **`.transfer()`/`.transferToFixedLength()`** — real ownership/aliasing features (a transferred buffer detaches; live views must observe a resize) that need their own design pass. Fixed-length only for v1.
- **Atomics / SharedArrayBuffer** — a different concern (cross-thread/concurrency primitives), not a natural extension of "buffer with views." Left as its own future decision.
- **Any JS-value coercion**: `ToIndex`/`ToNumber`/`ToBigInt`, `ToUint8Clamp` (the clamped-on-write behavior real `Uint8ClampedArray` has — `arr[0] = 300` becomes `255`), negative-index clamping for `.slice()`. This library takes already-resolved, in-range Zig values/indices; JS-specific conversion belongs to the future wiring phase (same division of responsibility `z-bigint`'s `fromDigitText` already established: it takes clean digit text, not an arbitrary user string).
- `ArrayBuffer.isView`, constructor/prototype shape, `.byteLength` as an accessor — all JSValue/property-system concerns.

## Design

- `ArrayBuffer.init(allocator, byte_length) Allocator.Error!ArrayBuffer` / `.deinit(self)` / `.byteLength(self) usize` / `.slice(self, allocator, start, end) BufferError!ArrayBuffer`
- `DataView.init(buffer: *ArrayBuffer, byte_offset, byte_length: ?usize) BufferError!DataView`, then `.getXxx(self, offset[, little_endian]) BufferError!T` / `.setXxx(self, offset, value[, little_endian]) BufferError!void` for each of the 10 element kinds.
- `TypedArrayView(comptime T: type)`: `.init(buffer: *ArrayBuffer, byte_offset, len: ?usize) BufferError!Self`, `.get(self, index) BufferError!T`, `.set(self, index, value) BufferError!void`, `.byteLength(self) usize`. Concrete aliases exported from `zbuffer.zig`: `Int8Array`, `Uint8Array`, `Int16Array`, `Uint16Array`, `Int32Array`, `Uint32Array`, `Float32Array`, `Float64Array`, `BigInt64Array`, `BigUint64Array`.
- Implementation note: both `DataView` and `TypedArrayView` route every access through a shared `codec.zig` (`readNum`/`writeNum` over `std.mem.readInt`/`writeInt`, floats via same-width unsigned int + `@bitCast`) rather than any `@ptrCast`/`@alignCast` to `*T` — this sidesteps alignment hazards entirely; the only alignment contract that matters is `byte_offset % @sizeOf(T) == 0` at construction time (`error.Misaligned`), never the underlying allocation's own alignment.

## Usage

```zig
const zbuffer = @import("zbuffer");

var buf = try zbuffer.ArrayBuffer.init(allocator, 16);
defer buf.deinit();

const dv = try zbuffer.DataView.init(&buf, 0, null);
try dv.setInt32(0, -1, true); // littleEndian
const back = try dv.getInt32(0, true); // -1

const ints = try zbuffer.Int32Array.init(&buf, 0, 4); // 4 elements, native endian
try ints.set(0, 42);
const v = try ints.get(0); // 42
```
