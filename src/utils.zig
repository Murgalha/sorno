const maxInt = @import("std").math.maxInt;
const c = @import("c.zig");
const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;

pub fn fromCString(allocator: *const mem.Allocator, str: [*c]u8) []u8 {
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    list.appendSlice(std.mem.span(str)) catch unreachable;

    return list.toOwnedSlice();
}

pub fn parseU64(buf: []const u8, radix: u8) !u64 {
    var x: u64 = 0;

    for (buf) |char| {
        const digit = charToDigit(char);

        if (digit >= radix) {
            return error.InvalidChar;
        }

        // x *= radix
        if (@mulWithOverflow(u64, x, radix, &x)) {
            return error.Overflow;
        }

        // x += digit
        if (@addWithOverflow(u64, x, digit, &x)) {
            return error.Overflow;
        }
    }

    return x;
}

fn charToDigit(char: u8) u8 {
    return switch (char) {
        '0'...'9' => char - '0',
        'A'...'Z' => char - 'A' + 10,
        'a'...'z' => char - 'a' + 10,
        else => maxInt(u8),
    };
}
