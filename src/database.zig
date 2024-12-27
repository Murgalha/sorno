const std = @import("std");
const c = @import("c.zig");
const dblogic = @import("dblogic.zig");
const sqlite3 = c.sqlite3;
const dm = @import("datamodels.zig");
const Element = dm.Element;
const Target = dm.Target;
const Profile = dm.Profile;
const printElement = dm.printElement;
const printTarget = dm.printTarget;
const printProfile = dm.printProfile;
const mem = std.mem;
const ArrayList = std.ArrayList;

pub const DatabaseError = error{
    InvalidType,
};

pub const Database = struct {
    const Self = @This();
    allocator: *const mem.Allocator,
    connection: ?*sqlite3,

    pub fn open(allocator: *const mem.Allocator) !Self {
        const path = try getDbPath(allocator);
        const conn = try dblogic.openConnection(allocator, path);

        return Self{
            .allocator = allocator,
            .connection = conn,
        };
    }

    pub fn close(self: *const Self) void {
        dblogic.closeConnection(self.connection);
    }

    pub fn insert(self: *const Self, data: anytype) !void {
        switch (@TypeOf(data)) {
            Element => {
                try dblogic.insertElement(self.allocator, self.connection, data);
            },
            Profile => {
                try dblogic.insertProfile(self.allocator, self.connection, data);
            },
            Target => {
                try dblogic.insertTarget(self.allocator, self.connection, data);
            },
            else => {
                return DatabaseError.InvalidType;
            },
        }
    }

    pub fn selectUnlinkedElements(self: *const Self) ![]Element {
        return dblogic.retrieveUnlinkedElements(self.allocator, self.connection);
    }

    pub fn selectProfileNames(self: *const Self) ![]Profile {
        return dblogic.retrieveProfileNames(self.allocator, self.connection);
    }

    pub fn selectProfile(self: *const Self, profile_name: []u8) !Profile {
        return dblogic.retrieveFullProfile(self.allocator, self.connection, profile_name);
    }

    pub fn selectTargets(self: *const Self) ![]Target {
        return dblogic.retrieveTargets(self.allocator, self.connection);
    }

    pub fn linkElement(self: *const Self, element: Element, profile: Profile) !void {
        try dblogic.insertProfileElement(self.allocator, self.connection, element, profile);
    }

    fn getDbPath(allocator: *const mem.Allocator) ![]u8 {
        var list = ArrayList(u8).init(allocator.*);
        defer list.deinit();

        var data_dir: [*c]u8 = c.getenv("XDG_CONFIG_HOME");
        if (data_dir != null) {
            try list.appendSlice(mem.span(data_dir));
            try list.appendSlice("/sorno/db/");
        } else {
            data_dir = c.getenv("HOME");
            try list.appendSlice(mem.span(data_dir));
            try list.appendSlice("/.local/share/sorno/db/");
        }

        return list.toOwnedSlice();
    }
};
