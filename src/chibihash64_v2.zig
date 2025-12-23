const std = @import("std");
const testing = std.testing;

/// Load 32-bit little endian value from byte slice
inline fn load32le(p: []const u8) u64 {
    return @as(u64, p[0]) |
        @as(u64, p[1]) << 8 |
        @as(u64, p[2]) << 16 |
        @as(u64, p[3]) << 24;
}

/// Load 64-bit little endian value from byte slice
inline fn load64le(p: []const u8) u64 {
    return load32le(p[0..4]) | (load32le(p[4..8]) << 32);
}

/// Rotate left
inline fn rotl(x: u64, n: u6) u64 {
    const shift = @as(u6, @intCast(64 -% @as(u7, n)));
    return (x << n) | (x >> shift);
}

/// Compute 64-bit hash of input data with optional seed (V2 algorithm)
pub fn chibihash64(input: []const u8, seed: u64) u64 {
    const K: u64 = 0x2B7E151628AED2A7; // digits of e
    const seed2 = rotl(seed -% K, 15) +% rotl(seed -% K, 47);
    const k_squared_xor_k = @as(u64, @intCast((@as(u128, K) *% K) % (1 << 64))) ^ K;
    var h = [_]u64{ seed, seed +% K, seed2, seed2 +% k_squared_xor_k };

    var p = input;
    var l = p.len;
    const original_len = l; // Store original length

    // Process 32-byte chunks
    while (l >= 32) : (l -= 32) {
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            const stripe = load64le(p[i * 8 ..][0..8]);
            h[i] = (stripe +% h[i]) *% K;
            h[(i + 1) & 3] +%= rotl(stripe, 27);
        }
        p = p[32..];
    }

    // Process 8-byte chunks
    while (l >= 8) : (l -= 8) {
        h[0] ^= load32le(p[0..4]);
        h[0] *%= K;
        h[1] ^= load32le(p[4..8]);
        h[1] *%= K;
        p = p[8..];
    }

    // Handle remaining bytes
    if (l >= 4) {
        h[2] ^= load32le(p[0..4]);
        h[3] ^= load32le(p[l - 4 ..][0..4]);
    } else if (l > 0) {
        h[2] ^= p[0];
        h[3] ^= p[l / 2] | (@as(u64, p[l - 1]) << 8);
    }

    h[0] +%= rotl(h[2] *% K, 31) ^ (h[2] >> 31);
    h[1] +%= rotl(h[3] *% K, 31) ^ (h[3] >> 31);
    h[0] *%= K;
    h[0] ^= h[0] >> 31;
    h[1] +%= h[0];

    // Use original_len instead of l for final mixing
    var x = @as(u64, @intCast(original_len)) *% K;
    x ^= rotl(x, 29);
    x +%= seed;
    x ^= h[1];

    x ^= rotl(x, 15) ^ rotl(x, 42);
    x *%= K;
    x ^= rotl(x, 13) ^ rotl(x, 31);

    return x;
}

// The HashMap and HashContext implementations remain the same as V1
pub fn HashMap(comptime K: type, comptime V: type) type {
    return std.hash_map.HashMap(K, V, HashContext(K), std.hash_map.default_max_load_percentage);
}

pub fn HashContext(comptime T: type) type {
    return struct {
        pub fn hash(self: @This(), key: T) u64 {
            _ = self;
            switch (@typeInfo(T)) {
                .pointer => |ptr| {
                    if (ptr.size == .slice and ptr.child == u8) {
                        return chibihash64(key, 0);
                    }
                },
                else => {},
            }
            const bytes = std.mem.asBytes(&key);
            return chibihash64(bytes, 0);
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
        .{ .input = "", .seed = 0, .expected = 0xD4F69E3ECCF128FC },
        .{ .input = "", .seed = 55555, .expected = 0x58AEE94CA9FB5092 },
        .{ .input = "hi", .seed = 0, .expected = 0x92C85CA994367DAC },
        .{ .input = "123", .seed = 0, .expected = 0x788A224711FF6E25 },
        .{ .input = "abcdefgh", .seed = 0, .expected = 0xA2E39BE0A0689B32 },
        .{ .input = "Hello, world!", .seed = 0, .expected = 0xABF8EB3100B2FEC7 },
        .{ .input = "qwertyuiopasdfghjklzxcvbnm123456", .seed = 0, .expected = 0x90FC5DB7F56967FA },
        .{ .input = "qwertyuiopasdfghjklzxcvbnm123456789", .seed = 0, .expected = 0x6DCDCE02882A4975 },
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
