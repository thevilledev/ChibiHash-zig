const std = @import("std");
const testing = std.testing;

/// Load 64-bit little endian value from byte slice
inline fn load64le(p: []const u8) u64 {
    return @as(u64, p[0]) << 0 |
        @as(u64, p[1]) << 8 |
        @as(u64, p[2]) << 16 |
        @as(u64, p[3]) << 24 |
        @as(u64, p[4]) << 32 |
        @as(u64, p[5]) << 40 |
        @as(u64, p[6]) << 48 |
        @as(u64, p[7]) << 56;
}

/// Compute 64-bit hash of input data with optional seed
pub fn chibihash64(input: []const u8, seed: u64) u64 {
    const P1 = 0x2B7E151628AED2A5;
    const P2 = 0x9E3793492EEDC3F7;
    const P3 = 0x3243F6A8885A308D;

    var h = [_]u64{ P1, P2, P3, seed };
    var k = input;
    var l = k.len;

    // Process 32-byte chunks
    while (l >= 32) : (l -= 32) {
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            const lane = load64le(k[i * 8 ..][0..8]);
            h[i] ^= lane;
            h[i] *%= P1;
            h[(i + 1) & 3] ^= (lane << 40) | (lane >> 24);
        }
        k = k[32..];
    }

    // Mix in length
    h[0] += (@as(u64, @intCast(input.len)) << 32) | (@as(u64, @intCast(input.len)) >> 32);

    // Handle single byte if present
    if ((l & 1) != 0) {
        h[0] ^= k[0];
        l -= 1;
        k = k[1..];
    }
    h[0] *%= P2;
    h[0] ^= h[0] >> 31;

    // Process remaining 8-byte chunks
    var i: usize = 1;
    while (l >= 8) : (l -= 8) {
        h[i] ^= load64le(k[0..8]);
        h[i] *%= P2;
        h[i] ^= h[i] >> 31;
        k = k[8..];
        i += 1;
    }

    // Process remaining bytes in pairs
    i = 0;
    while (l > 0) : (l -= 2) {
        const v = if (l >= 2) k[0] | (@as(u64, k[1]) << 8) else k[0];
        h[i] ^= v;
        h[i] *%= P3;
        h[i] ^= h[i] >> 31;
        k = k[2..];
        i += 1;
    }

    // Final mixing
    var x = seed;
    x ^= h[0] *% ((h[2] >> 32) | 1);
    x ^= h[1] *% ((h[3] >> 32) | 1);
    x ^= h[2] *% ((h[0] >> 32) | 1);
    x ^= h[3] *% ((h[1] >> 32) | 1);

    // MoreMur mixing
    x ^= x >> 27;
    x *%= 0x3C79AC492BA7B653;
    x ^= x >> 33;
    x *%= 0x1C69B3F74AC4AE35;
    x ^= x >> 27;

    return x;
}

/// HashMap implementation using ChibiHash64
pub fn HashMap(comptime K: type, comptime V: type) type {
    return std.hash_map.HashMap(K, V, HashContext(K), std.hash_map.default_max_load_percentage);
}

/// Hash context for use with standard library containers
pub fn HashContext(comptime T: type) type {
    return struct {
        pub fn hash(self: @This(), key: T) u64 {
            _ = self;
            switch (@typeInfo(T)) {
                .Pointer => |ptr| {
                    if (ptr.size == .Slice and ptr.child == u8) {
                        // Special case for []const u8 and []u8
                        return chibihash64(key, 0);
                    }
                },
                else => {},
            }
            // For other types, hash their bytes
            var bytes: [@sizeOf(T)]u8 = undefined;
            std.mem.writeIntLittle(T, &bytes, key);
            return chibihash64(&bytes, 0);
        }

        pub fn eql(self: @This(), a: T, b: T) bool {
            _ = self;
            return std.meta.eql(a, b);
        }
    };
}

test "known test vectors" {
    const TestVector = struct {
        input: []const u8,
        seed: u64,
        expected: u64,
    };

    const test_vectors = [_]TestVector{
        .{ .input = "", .seed = 0, .expected = 0x9EA80F3B18E26CFB },
        .{ .input = "", .seed = 55555, .expected = 0x2EED9399FC4AC7E5 },
        .{ .input = "hi", .seed = 0, .expected = 0xAF98F3924F5C80D6 },
        .{ .input = "123", .seed = 0, .expected = 0x893A5CCA05B0A883 },
        .{ .input = "abcdefgh", .seed = 0, .expected = 0x8F922660063E3E75 },
        .{ .input = "Hello, world!", .seed = 0, .expected = 0x5AF920D8C0EBFE9F },
        .{ .input = "qwertyuiopasdfghjklzxcvbnm123456", .seed = 0, .expected = 0x2EF296DB634F6551 },
        .{ .input = "qwertyuiopasdfghjklzxcvbnm123456789", .seed = 0, .expected = 0x0F56CF3735FFA943 },
    };

    for (test_vectors) |vec| {
        try testing.expectEqual(vec.expected, chibihash64(vec.input, vec.seed));
    }
}

test "HashMap basic usage" {
    const allocator = testing.allocator;
    var map = HashMap([]const u8, i32).init(allocator);
    defer map.deinit();

    try map.put("hello", 42);
    try map.put("world", 24);

    try testing.expectEqual(@as(i32, 42), map.get("hello").?);
    try testing.expectEqual(@as(i32, 24), map.get("world").?);
    try testing.expect(map.get("nonexistent") == null);
}
