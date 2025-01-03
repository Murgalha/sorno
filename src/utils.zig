const maxInt = @import("std").math.maxInt;
const c = @import("c.zig");
const std = @import("std");
const mem = std.mem;
const cstr = std.cstr;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

const max_alloc_size = 1_000;

pub fn readU64(allocator: *const mem.Allocator, prompt: []const u8) !u64 {
    return try parseU64(try readLine(allocator, prompt), 10);
}

pub fn readLine(allocator: *const mem.Allocator, prompt: []const u8) ![]u8 {
    if (prompt.len > 0) {
        try stdout.print("{s}", .{prompt});
    }
    return (try stdin.readUntilDelimiterOrEofAlloc(allocator.*, '\n', max_alloc_size)).?;
}

pub fn getDelimIndexes(allocator: *const mem.Allocator, str: []u8, delim: u8) ![]usize {
    var list = ArrayList(usize).init(allocator.*);
    defer list.deinit();

    var i: usize = 0;
    while (i < str.len) : (i += 1) {
        if (str[i] == delim) {
            try list.append(i);
        }
    }
    return list.toOwnedSlice();
}

pub fn fromCString(allocator: *const mem.Allocator, str: [*c]u8) ![]u8 {
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    // TODO: Treat error correctly
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
        var ov = @mulWithOverflow(x, radix);
        if (ov[1] != 0) {
            return error.Overflow;
        }
        x = ov[0];

        // x += digit
        ov = @addWithOverflow(x, digit);
        if (ov[1] != 0) {
            return error.Overflow;
        }
        x = ov[0];
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
