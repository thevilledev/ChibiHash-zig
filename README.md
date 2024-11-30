# ChibiHash64-Zig

A Zig port of [ChibiHash64](https://github.com/N-R-K/ChibiHash) - a small, fast 64-bit hash function.

## Features
- Simple 64-bit hash function
- HashMap implementation
- Thoroughly tested with known test vectors

## Usage

```
const std = @import("std");
const ChibiHash64 = @import("chibihash64.zig");

// Basic hashing
const hash = ChibiHash64.hash("Hello, world!", 0);

// Using HashMap
var map = ChibiHash64.HashMap([]const u8, i32).init(allocator);
defer map.deinit();
```

## License

MIT.
