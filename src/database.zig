const std = @import("std");
const c = @import("c.zig");
const sqlite3 = c.sqlite3;
const dm = @import("datamodels.zig");
const sqlite = @import("sqlite.zig");
const DbHandle = sqlite.DbHandle;
const utils = @import("utils.zig");
const qStrings = @import("querystrings.zig");
const Element = dm.Element;
const Target = dm.Target;
const Profile = dm.Profile;
const printElement = dm.printElement;
const printTarget = dm.printTarget;
const printProfile = dm.printProfile;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();

pub const DatabaseError = error{
    InvalidType,
};

pub const Database = struct {
    const Self = @This();
    allocator: *const mem.Allocator,
    databasePath: []const u8,

    pub fn init(allocator: *const mem.Allocator) !Self {
        const path = try getDbFullPath(allocator);
        _ = try createPath(allocator, path);

        var db = Self{
            .allocator = allocator,
            .databasePath = path,
        };

        try db.createAllTables();

        return db;
    }

    pub fn deinit(_: *const Self) void {}

    pub fn insert(self: *const Self, data: anytype) !void {
        var connection = sqlite.DbHandle.init(self.databasePath);
        defer connection.deinit();

        switch (@TypeOf(data)) {
            Element => {
                try connection.execute(
                    self.allocator,
                    qStrings.INSERT_ELEMENT,
                    .{ data.name, data.source, data.destination },
                );
            },
            Profile => {
                try connection.execute(
                    self.allocator,
                    qStrings.INSERT_PROFILE,
                    .{data.name},
                );
            },
            Target => {
                try connection.execute(
                    self.allocator,
                    qStrings.INSERT_TARGET,
                    .{ data.name, data.path, data.address, data.user },
                );
            },
            else => return DatabaseError.InvalidType,
        }
    }

    pub fn selectUnlinkedElements(self: *const Self) ![]Element {
        var connection = sqlite.DbHandle.init(self.databasePath);
        defer connection.deinit();

        var list = ArrayList(Element).init(self.allocator.*);

        const slice = try connection.executeWithReturn(self.allocator, qStrings.SELECT_UNLINKED_ELEMENTS, .{});
        defer self.allocator.*.free(slice);

        for (slice) |row| {
            const element: Element = .{
                .id = try std.fmt.parseInt(u64, row.get("id").?, 10),
                .name = @constCast(row.get("name").?),
                .source = @constCast(row.get("source").?),
                .destination = @constCast(row.get("destination").?),
            };

            try list.append(element);
        }

        return try list.toOwnedSlice();
    }

    pub fn selectProfileNames(self: *const Self) ![]Profile {
        //TODO: Create struct with name only instead of using full profile
        var connection = sqlite.DbHandle.init(self.databasePath);
        defer connection.deinit();

        var list = ArrayList(Profile).init(self.allocator.*);
        defer list.deinit();

        const slice = try connection.executeWithReturn(self.allocator, qStrings.SELECT_ALL_PROFILE_NAMES, .{});
        defer self.allocator.*.free(slice);

        for (slice) |row| {
            const profile: Profile = .{
                .id = try std.fmt.parseInt(u64, row.get("id").?, 10),
                .name = @constCast(row.get("name").?),
                .elements = &.{},
            };

            try list.append(profile);
        }

        return try list.toOwnedSlice();
    }

    pub fn selectProfile(self: *const Self, profile_name: []u8) !Profile {
        var connection = sqlite.DbHandle.init(self.databasePath);
        defer connection.deinit();

        // TODO: Retrieve profile based on ID, not name
        var list = ArrayList(Element).init(self.allocator.*);
        defer list.deinit();

        const slice = try connection.executeWithReturn(self.allocator, qStrings.SELECT_FULL_PROFILE, .{profile_name});
        defer self.allocator.*.free(slice);

        std.debug.assert(slice.len == 1);
        const profileName = @constCast(slice[0].get("profile_name").?);
        const profileId = try std.fmt.parseInt(u64, slice[0].get("profile_id").?, 10);

        for (slice) |row| {
            const element = Element{
                .id = try std.fmt.parseInt(u64, row.get("element_id").?, 10),
                .name = @constCast(row.get("element_name").?),
                .source = @constCast(row.get("element_source").?),
                .destination = @constCast(row.get("element_destination").?),
            };

            try list.append(element);
        }

        std.debug.assert(slice.len == 1);

        return .{
            .id = profileId,
            .name = profileName,
            .elements = try list.toOwnedSlice(),
        };
    }

    pub fn selectTargets(self: *const Self) ![]Target {
        var connection = sqlite.DbHandle.init(self.databasePath);
        defer connection.deinit();

        const slice = try connection.executeWithReturn(self.allocator, qStrings.SELECT_ALL_TARGETS, .{});
        defer self.allocator.*.free(slice);

        var list = ArrayList(Target).init(self.allocator.*);
        defer list.deinit();

        for (slice) |row| {
            const target: Target = .{
                .id = try std.fmt.parseInt(u64, row.get("id").?, 10),
                .name = @constCast(row.get("name").?),
                .user = @constCast(row.get("user").?),
                .address = @constCast(row.get("address").?),
                .path = @constCast(row.get("path").?),
            };

            try list.append(target);
        }

        return try list.toOwnedSlice();
    }

    pub fn linkElement(self: *const Self, element: Element, profile: Profile) !void {
        var connection = sqlite.DbHandle.init(self.databasePath);
        defer connection.deinit();

        try connection.execute(self.allocator, qStrings.INSERT_PROFILEELEMENT, .{ profile.id, element.id });
    }

    fn getDbFullPath(allocator: *const mem.Allocator) ![]u8 {
        var list = ArrayList(u8).init(allocator.*);
        defer list.deinit();

        var data_dir: [*c]u8 = c.getenv("XDG_DATA_HOME");
        if (data_dir != null) {
            try list.appendSlice(mem.span(data_dir));
            try list.appendSlice("/sorno/db/");
        } else {
            data_dir = c.getenv("HOME");
            try list.appendSlice(mem.span(data_dir));
            try list.appendSlice("/.local/share/sorno/db/");
        }

        try list.appendSlice("sorno.db");
        return list.toOwnedSlice();
    }

    fn createAllTables(self: *const Self) !void {
        var connection = sqlite.DbHandle.init(self.databasePath);
        defer connection.deinit();

        _ = try connection
            .execute(self.allocator, std.mem.span(qStrings.CREATE_PROFILE_TABLE.ptr), .{});
        _ = try connection
            .execute(self.allocator, std.mem.span(qStrings.CREATE_TARGET_TABLE.ptr), .{});
        _ = try connection
            .execute(self.allocator, std.mem.span(qStrings.CREATE_ELEMENT_TABLE.ptr), .{});
        _ = try connection
            .execute(self.allocator, std.mem.span(qStrings.CREATE_PROFILEELEMENTS_TABLE.ptr), .{});
    }

    pub fn createPath(allocator: *const mem.Allocator, path: []u8) !void {
        const indexes = try utils.getDelimIndexes(allocator, path, '/');
        var list = ArrayList(u8).init(allocator.*);
        defer list.deinit();

        var start: usize = 0;
        for (indexes) |index| {
            const partial_path = path[start..index];

            try list.appendSlice(partial_path);

            const fullpath = try allocator.*.dupeZ(u8, list.items);

            const dir: ?*c.DIR = c.opendir(fullpath);
            if (dir != null) {
                _ = c.closedir(dir);
            } else if (@as(c_int, 2) == c.__errno_location().*) {
                _ = c.mkdir(fullpath, @bitCast(@as(c_int, 511)));
            } else {
                try stdout.print("Could not create directory {s}\n", .{fullpath});
            }

            start = index;
        }
    }
};
