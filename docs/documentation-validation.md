# Documentation validation

The 0.1.0 documentation was generated and validated with Zig 0.17.0.

## Public declaration coverage

The following counts include public function and constant declarations in the public API implementation and root facade. Each declaration has a preceding Zig `///` documentation comment. Fields are also documented, but are not included in these counts. Internal codec helpers are outside this coverage scope.

| Source | Documented declarations | Total declarations |
| --- | ---: | ---: |
| `src/zbuffer.zig` | 14 | 14 |
| `src/array_buffer.zig` | 6 | 6 |
| `src/data_view.zig` | 23 | 23 |
| `src/typed_array.zig` | 7 | 7 |
| **Total** | **50** | **50** |

This measures documentation presence, not exhaustive behavioral coverage.

## Checks performed

- `zig build test docs --summary all`: 23 tests passed; documentation generation succeeded.
- `zig fmt --check build.zig build.zig.zon src tests`: passed.
- `git diff --check`: passed.
- The README usage example compiled and passed as a Zig test with `std.testing.allocator`.
- The generated site was served over HTTP and checked in Chromium: the root redirected to `docs/`, the root API declarations rendered, and navigation to `ArrayBuffer` rendered its documented methods.

GitHub Actions repeats formatting checks, tests, documentation generation, and required-asset checks before deploying to GitHub Pages.
