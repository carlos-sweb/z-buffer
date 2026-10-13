# Public API parity with Node.js Buffer

This analysis compares z-buffer 0.1.0, targeting Zig 0.17.0, with **Node.js v26.5.0**, the version installed on the system used for the review. The comparison concerns functional capabilities and observable behavior, rather than reproducing JavaScript's prototype chain.

## Conclusion

The repository provides byte storage, shared views, and numeric access. It has partial functional parity with Node.js `Buffer`, but does not yet implement most of its higher-level operations. Zig's lack of a native JavaScript prototype chain does not prevent implementing those capabilities with struct methods and functions.

Node.js `Buffer` combines a byte view with numeric and utility operations. In z-buffer, those responsibilities are distributed across `ArrayBuffer`, `DataView`, and `TypedArrayView(T)`. The current library is a foundation for a Buffer-like API, rather than a complete implementation of one.

## Public API

The root module, `src/zbuffer.zig`, exports:

- `ArrayBuffer`: `init`, `deinit`, `byteLength`, `slice`, and the `allocator`, `bytes`, and `is_shared` fields.
- `DataView`: `init`, 20 numeric getters/setters for 10 numeric types, and the `buffer`, `byte_offset`, and `byte_length` fields.
- `TypedArrayView(T)`: `init`, `get`, `set`, `byteLength`, `elem_size`, and the `buffer`, `byte_offset`, and `len` fields.
- Ten concrete typed views: `Int8Array`, `Uint8Array`, `Int16Array`, `Uint16Array`, `Int32Array`, `Uint32Array`, `Float32Array`, `Float64Array`, `BigInt64Array`, and `BigUint64Array`.
- `BufferError`: `OutOfBounds`, `Misaligned`, and `OutOfMemory`.

`codec.zig` supplies internal implementation helpers; the root module does not export it as part of the public facade.

## Capability comparison

| Node.js Buffer capability | Current z-buffer equivalent | Parity |
| --- | --- | --- |
| Zero-initialized allocation | `ArrayBuffer.init` | Equivalent for basic allocation; no fill argument |
| Individual byte access | `bytes[i]` or `Uint8Array.get/set` | Supported, with different bounds behavior |
| Signed/unsigned 8-, 16-, and 32-bit numeric access | `DataView.get/setInt/Uint` | Equivalent for valid typed inputs |
| Signed/unsigned 64-bit numeric access | `get/setBigInt64/BigUint64` | Equivalent storage, using Zig `i64/u64` rather than JS `bigint` |
| Float/double access | `get/setFloat32/Float64` | Supported |
| Little-/big-endian numeric access | Explicit `little_endian` argument | Supported |
| Variable-width integer access, 1–6 bytes | No corresponding public method | Partial: fixed 1-, 2-, and 4-byte integer operations exist |
| Views sharing backing memory | `DataView.init`, `Uint8Array.init` | Supported as a mechanism |
| `slice` / `subarray` on a byte view | No corresponding view methods | Incomplete; `ArrayBuffer.slice` copies |
| `from`, `concat`, copying between buffers | Only `ArrayBuffer.slice` offers a dedicated copy operation | Partial |
| `fill`, search, comparison, equality, byte swapping | No dedicated public methods | Missing |
| UTF-8, hex, base64, other string encodings, JSON conversion | No dedicated public methods | Missing |
| Inherited operations such as `map`, `filter`, `sort`, `reduce`, and bulk `set` | No corresponding view methods | Missing |
| Unsafe allocation and allocation pooling | No public equivalents | Missing |

Some missing operations can already be composed using the exposed byte slice and Zig's standard library. That does not make them part of this repository's public API.

## Semantic differences

### Copying versus shared views

Node.js `Buffer.slice()` and `Buffer.subarray()` produce views sharing the original storage. Mutating those views changes the original bytes. In contrast, this repository's `ArrayBuffer.slice()` creates an independent copy, matching JavaScript `ArrayBuffer.prototype.slice()`.

Constructing a `Uint8Array` or `DataView` over the existing `ArrayBuffer` provides shared storage, but does not expose the same convenience operations, relative slicing behavior, or negative-index handling as Buffer.

### Scalar versus bulk set

`TypedArrayView.set(index, value)` writes one element. The `set(source, offset)` operation inherited by Node.js Buffer copies multiple elements. The shared name does not imply equivalent behavior.

### Types, errors, and return values

Zig accepts already-resolved typed values. JavaScript's dynamic coercion and runtime type checks are not reproduced. Numeric writes in Node return the next byte offset; this library's setters return `void` on success.

Node's out-of-range indexed reads return `undefined`. The typed view's `get` returns `error.OutOfBounds`. Direct access to `bytes[i]` follows Zig's bounds and runtime-safety rules. Numeric Buffer reads outside the buffer throw an exception.

The library requires explicit offsets and explicit endianness for multi-byte DataView operations. It does not reproduce optional JS arguments, property descriptors, `instanceof`, symbols, or prototype mutation.

### Ownership and lifetime

`ArrayBuffer` owns an allocator-backed byte slice and must be explicitly deinitialized. Its views hold pointers to the owner. The owner must remain valid at a stable address, and its storage must remain allocated, while those views are used. Copying the owning struct does not create a second independent allocation.

Node manages the backing storage lifetime automatically. Reproducing shared byte behavior in Zig therefore requires an explicit ownership contract, even when the bytes are identical.

### SharedArrayBuffer and newer ECMAScript features

`is_shared` is a discriminator for downstream integration, not an implementation of synchronization or Atomics. Resizable buffers, detachment, transfer, and shared-memory lifecycle semantics are absent.

The installed Node.js DataView also exposes `getFloat16` and `setFloat16`; the public DataView in this repository does not. This is a gap relative to modern DataView, separately from Node Buffer's fixed-width numeric API.

## Bounds-checking finding

`DataView.init` checks `byte_offset + len`, and its internal `window` checks `offset + n`. Extreme `usize` arguments can overflow before an `OutOfBounds` error is returned. With runtime safety enabled this can panic; without safety, wrapped arithmetic can invalidate the intended check. Subtraction-based checks after validating the starting offset would avoid the overflow.

This issue was identified during analysis and is not fixed by the documentation or Zig-version migration. The public fields are also mutable, so callers must preserve the invariants established by constructors.

## Validation and limits

The installed Node.js was introspected to inventory Buffer methods, inherited typed-array methods, ArrayBuffer methods, and DataView methods. Eighteen numeric write cases compared Buffer output with Node's own DataView across all ten supported numeric kinds and both byte orders where applicable. These checks passed. Additional probes confirmed:

- Buffer slicing shares storage.
- JavaScript ArrayBuffer slicing copies storage.
- `Buffer.from(arrayBuffer, offset, length)` shares storage.
- Out-of-range indexed reads return `undefined`.
- Numeric writes return the next byte offset.

The Zig migration passed the repository's 23 tests in `debug`, `safe`, `fast`, and `small` modes. The Node probes and code review establish the capability mapping; they are **not an exhaustive differential test suite between Node and Zig**. Full parity would require testing matching operations, edge cases, numeric representations, bounds, overlapping copies, encodings, and ownership semantics.

## Reference

[Node.js v26.5.0 Buffer documentation](https://nodejs.org/download/release/v26.5.0/docs/api/buffer.html).
