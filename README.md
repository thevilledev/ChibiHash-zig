# ChibiHash64-Zig

A Zig port of [ChibiHash64](https://github.com/N-R-K/ChibiHash) - a small, fast 64-bit hash function. See the article [ChibiHash: A small, fast 64-bit hash function](https://nrk.neocities.org/articles/chibihash) for more information.

All credit for the algorithm goes to [N-R-K](https://github.com/N-R-K).

## Features

- Simple 64-bit hash function
- Supports both v1 and v2 of the hash function
- HashMap implementation
- Thoroughly tested with known test vectors

## Usage

```
const std = @import("std");
const ChibiHash64v1 = @import("chibihash64_v1.zig");
const ChibiHash64v2 = @import("chibihash64_v2.zig");

// Basic hashing v1
const hash = ChibiHash64v1.hash("Hello, world!", 0);

// Using HashMap v1
var map = ChibiHash64v1.HashMap([]const u8, i32).init(allocator);
defer map.deinit();

// Basic hashing v2
const hash = ChibiHash64v2.hash("Hello, world!", 0);

// Using HashMap v2
var map = ChibiHash64v2.HashMap([]const u8, i32).init(allocator);
defer map.deinit();
```

See `example/example.zig` for a complete example. Run it with `zig build run-example`.

## License

MIT.
