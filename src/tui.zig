const std = @import("std");
const c = @import("c.zig");
const dm = @import("datamodels.zig");
const utils = @import("utils.zig");
const mem = std.mem;
const Element = dm.Element;
const Profile = dm.Profile;
const Target = dm.Target;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

const max_alloc_size = 1_000;

const UiError = error{
    InvalidInput,
    NoData,
};

pub const Tui = struct {
    const Self = @This();
    allocator: *const mem.Allocator,

    pub fn init(allocator: *const mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn deinit(_: *const Self) void {
        //
    }

    pub fn readTarget(self: *const Self) !Target {
        var target: Target = undefined;

        target.name = try self.readNotEmpty("Enter the name of the target: ");
        target.address = try self.readLine("Enter the address of the target: ");
        target.user = try self.readLine("Enter the user to connect on the target: ");

        // Append trailing forward slash to avoid problems with rsync
        target.path = try self.readNotEmpty("Enter the path of the target: ");
        target.path = try self.maybeAppendForwardSlash(target.path);

        return target;
    }

    pub fn readElement(self: *const Self) !Element {
        var element: Element = undefined;

        element.name = try self.readNotEmpty("Enter the name of the element: ");
        element.source = try self.readNotEmpty("Enter the source path of the element: ");
        element.source = try self.maybeAppendForwardSlash(element.source);

        element.destination = try self.readLine("Enter the destination path of the element\n(If empty, will be considered basename(source)): ");
        if (element.destination.len == 0) {
            element.destination = try self.basename(element.source);
        }

        element.destination = try self.maybeAppendForwardSlash(element.destination);
        return element;
    }

    pub fn readProfile(self: *const Self) !Profile {
        var profile: Profile = undefined;

        profile.name = try self.readNotEmpty("Enter the name of the profile: ");
        profile.elements = &.{};
        return profile;
    }

    pub fn selectProfile(self: *const Self, prompt: []const u8, profiles: []Profile) !usize {
        if (profiles.len == 0) {
            return UiError.NoData;
        }

        return self.readOption(prompt, profiles);
    }

    pub fn selectElement(self: *const Self, prompt: []const u8, elements: []Element) !usize {
        if (elements.len == 0) {
            return UiError.NoData;
        }

        return self.readOption(prompt, elements);
    }

    pub fn selectTarget(self: *const Self, prompt: []const u8, targets: []Target) !usize {
        if (targets.len == 0) {
            return UiError.NoData;
        }

        return self.readOption(prompt, targets);
    }

    pub fn readU64(self: *const Self, prompt: []const u8) !u64 {
        return try utils.parseU64(try self.readLine(prompt), 10);
    }

    fn readLine(self: *const Self, prompt: []const u8) ![]u8 {
        if (prompt.len > 0) {
            try stdout.print("{s}", .{prompt});
        }
        return (try stdin.readUntilDelimiterOrEofAlloc(self.allocator.*, '\n', max_alloc_size)).?;
    }

    fn readNotEmpty(self: *const Self, prompt: []const u8) ![]u8 {
        var valid: bool = false;
        var str: []u8 = undefined;

        while (!valid) {
            str = try self.readLine(prompt);
            if (str.len != 0) {
                valid = true;
            } else {
                try stdout.print("Error! Must not be empty.\n", .{});
            }
        }
        return str;
    }

    fn maybeAppendForwardSlash(self: *const Self, path: []u8) ![]u8 {
        std.debug.print("Path: {s}\n", .{path});

        if (path[path.len - 1] == '/') {
            return path;
        }

        var list = ArrayList(u8).init(self.allocator.*);
        defer list.deinit();

        try list.appendSlice(path);
        try list.append('/');

        return list.toOwnedSlice();
    }

    fn readOption(self: *const Self, prompt: []const u8, data_slice: anytype) !usize {
        var valid = false;
        var n = data_slice.len;
        var opt: u64 = undefined;

        // TODO: Check for valid data types only
        while (!valid) {
            try stdout.print("{s}", .{prompt});

            var i: usize = 0;
            while (i < n) : (i += 1) {
                try stdout.print("{d}: {s}\n", .{ i + 1, data_slice[i].name });
            }

            opt = utils.parseU64(try self.readLine(""), 10) catch n + 1;

            if (opt > 0 and opt <= n) {
                valid = true;
            } else {
                try stdout.print("Invalid element\n", .{});
            }
        }
        return @as(usize, opt - 1);
    }

    fn basename(self: *const Self, path: []u8) ![]u8 {
        var list = ArrayList(u8).init(self.allocator.*);
        defer list.deinit();

        var indexes = try utils.getDelimIndexes(self.allocator, path, '/');

        if (indexes.len < 2) {
            try stdout.print("Given path might not be absolute path\n", .{});
        }

        // using -2 because the last slash is always the last character because
        // of maybeAppendForwardSlash
        // TODO: Check if above statement is true
        var last = indexes[indexes.len - 2];

        try list.appendSlice(path[last + 1 ..]);
        return list.toOwnedSlice();
    }
};
