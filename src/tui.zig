const std = @import("std");
const c = @import("c.zig");
const dm = @import("datamodels.zig");
const utils = @import("utils.zig");
const mem = std.mem;
const mm = @import("mainmenu.zig");
const MainMenu = mm.MainMenu;
const Element = dm.Element;
const Profile = dm.Profile;
const Target = dm.Target;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const Database = @import("database.zig").Database;

const UiError = error{
    InvalidInput,
    NoData,
};

pub const Tui = struct {
    const Self = @This();
    allocator: *const mem.Allocator,

    pub fn init(allocator: *const mem.Allocator) !Tui {
        return Tui{
            .allocator = allocator,
        };
    }

    pub fn deinit(_: *Self) void {
        //
    }

    pub fn readTarget(self: *Self) !Target {
        var target: Target = undefined;

        target.name = try self.readNotEmpty("Enter the name of the target: ");
        target.address = try utils.readLine(self.allocator, "Enter the address of the target: ");
        target.user = try utils.readLine(self.allocator, "Enter the user to connect on the target: ");

        // Append trailing forward slash to avoid problems with rsync
        target.path = try self.readNotEmpty("Enter the path of the target: ");
        target.path = try self.maybeAppendForwardSlash(target.path);

        return target;
    }

    pub fn readElement(self: *Self) !Element {
        var element: Element = undefined;

        element.name = try self.readNotEmpty("Enter the name of the element: ");
        element.source = try self.readNotEmpty("Enter the source path of the element: ");
        element.source = try self.maybeAppendForwardSlash(element.source);

        element.destination = try utils.readLine(self.allocator, "Enter the destination path of the element\n(If empty, will be considered basename(source)): ");
        if (element.destination.len == 0) {
            element.destination = try self.basename(element.source);
        }

        element.destination = try self.maybeAppendForwardSlash(element.destination);
        return element;
    }

    pub fn readProfile(self: *Self) !Profile {
        var profile: Profile = undefined;

        profile.name = try self.readNotEmpty("Enter the name of the profile: ");
        profile.elements = &.{};
        return profile;
    }

    pub fn selectProfile(self: *Self, prompt: []const u8, profiles: []Profile) !usize {
        if (profiles.len == 0) {
            return UiError.NoData;
        }

        return self.readOption(prompt, profiles);
    }

    pub fn selectElement(self: *Self, prompt: []const u8, elements: []Element) !usize {
        if (elements.len == 0) {
            return UiError.NoData;
        }

        return self.readOption(prompt, elements);
    }

    pub fn selectTarget(self: *Self, prompt: []const u8, targets: []Target) !usize {
        if (targets.len == 0) {
            return UiError.NoData;
        }

        return self.readOption(prompt, targets);
    }

    pub fn readTargetPassword(self: *Self, prompt: []const u8) ![]u8 {
        return utils.fromCString(self.allocator, c.getpass(try self.allocator.*.dupeZ(u8, prompt)));
    }

    fn readNotEmpty(self: *Self, prompt: []const u8) ![]u8 {
        var valid: bool = false;
        var str: []u8 = undefined;

        while (!valid) {
            str = try utils.readLine(self.allocator, prompt);
            if (str.len != 0) {
                valid = true;
            } else {
                try stdout.print("Error! Must not be empty.\n", .{});
            }
        }
        return str;
    }

    fn maybeAppendForwardSlash(self: *Self, path: []u8) ![]u8 {
        if (path[path.len - 1] == '/') {
            return path;
        }

        var list = ArrayList(u8).init(self.allocator.*);
        defer list.deinit();

        try list.appendSlice(path);
        try list.append('/');

        return list.toOwnedSlice();
    }

    fn readOption(self: *Self, prompt: []const u8, data_slice: anytype) !usize {
        var valid = false;
        const n = data_slice.len;
        var opt: u64 = undefined;

        // TODO: Check for valid data types only
        while (!valid) {
            try stdout.print("{s}", .{prompt});

            var i: usize = 0;
            while (i < n) : (i += 1) {
                try stdout.print("{d}: {s}\n", .{ i + 1, data_slice[i].name });
            }

            opt = utils.parseU64(try utils.readLine(self.allocator, ""), 10) catch n + 1;

            if (opt > 0 and opt <= n) {
                valid = true;
            } else {
                try stdout.print("Invalid element\n", .{});
            }
        }
        return @as(usize, opt - 1);
    }

    fn basename(self: *Self, path: []u8) ![]u8 {
        var list = ArrayList(u8).init(self.allocator.*);
        defer list.deinit();

        const indexes = try utils.getDelimIndexes(self.allocator, path, '/');

        if (indexes.len < 2) {
            try stdout.print("Given path might not be absolute path\n", .{});
        }

        // using -2 because the last slash is always the last character because
        // of maybeAppendForwardSlash
        // TODO: Check if above statement is true
        const last = indexes[indexes.len - 2];

        try list.appendSlice(path[last + 1 ..]);
        return list.toOwnedSlice();
    }
};
