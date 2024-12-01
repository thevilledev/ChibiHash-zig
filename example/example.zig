const std = @import("std");
const ChibiHash64v1 = @import("chibihash64_v1");
const ChibiHash64v2 = @import("chibihash64_v2");

pub fn main() !void {
    // Get an allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Basic hashing v1
    const hash_v1 = ChibiHash64v1.chibihash64("Hello, world!", 0);
    std.debug.print("V1 hash of 'Hello, world!': 0x{X}\n", .{hash_v1});

    // Using HashMap v1
    var map_v1 = ChibiHash64v1.HashMap([]const u8, i32).init(allocator);
    defer map_v1.deinit();
    try map_v1.put("example", 42);
    std.debug.print("V1 HashMap get 'example': {?}\n", .{map_v1.get("example")});

    // Basic hashing v2
    const hash_v2 = ChibiHash64v2.chibihash64("Hello, world!", 0);
    std.debug.print("V2 hash of 'Hello, world!': 0x{X}\n", .{hash_v2});

    // Using HashMap v2
    var map_v2 = ChibiHash64v2.HashMap([]const u8, i32).init(allocator);
    defer map_v2.deinit();
    try map_v2.put("example", 42);
    std.debug.print("V2 HashMap get 'example': {?}\n", .{map_v2.get("example")});
}
