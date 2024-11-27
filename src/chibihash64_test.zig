const std = @import("std");
const testing = std.testing;
const ChibiHash64 = @import("chibihash64.zig");

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
        try testing.expectEqual(vec.expected, ChibiHash64.chibihash64(vec.input, vec.seed));
    }
}

test "HashMap basic usage" {
    const allocator = testing.allocator;
    var map = ChibiHash64.HashMap([]const u8, i32).init(allocator);
    defer map.deinit();

    try map.put("hello", 42);
    try map.put("world", 24);

    try testing.expectEqual(@as(i32, 42), map.get("hello").?);
    try testing.expectEqual(@as(i32, 24), map.get("world").?);
    try testing.expect(map.get("nonexistent") == null);
}
