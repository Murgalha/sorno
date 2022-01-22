const std = @import("std");
const c = @import("c.zig");
const db = @import("db.zig");
const sqlite3 = c.sqlite3;
const Element = @import("data.zig").Element;
const Target = @import("data.zig").Target;
const Profile = @import("data.zig").Profile;
const printElement = @import("data.zig").printElement;
const printTarget = @import("data.zig").printTarget;
const printProfile = @import("data.zig").printProfile;
const mem = std.mem;
const ArrayList = std.ArrayList;
const retrieveTargets = @import("db.zig").retrieveTargets;

pub const DatabaseError = error{
    InvalidType,
};

pub const Database = struct {
    const Self = @This();
    allocator: *const mem.Allocator,
    connection: ?*sqlite3,

    pub fn open(allocator: *const mem.Allocator) !Self {
        var conn = try db.db_open();

        db.db_create_tables(conn);

        return Self{
            .allocator = allocator,
            .connection = conn,
        };
    }

    pub fn close(self: *const Self) void {
        db.db_close(self.connection);
    }

    pub fn insert(self: *const Self, data: anytype) !void {
        switch (@TypeOf(data)) {
            Element => {
                try db.insertElement(self.connection, data);
            },
            Profile => {
                try db.insertProfile(self.connection, data);
            },
            Target => {
                try db.insertTarget(self.connection, data);
            },
            else => {
                return DatabaseError.InvalidType;
            },
        }
    }

    pub fn selectUnlinkedElements(self: *const Self) ![]Element {
        return db.retrieveUnlinkedElements(self.allocator, self.connection);
    }

    pub fn selectProfileNames(self: *const Self) ![]Profile {
        return db.retrieveProfileNames(self.allocator, self.connection);
    }

    pub fn selectProfile(self: *const Self, profile_name: []u8) !Profile {
        return db.retrieveFullProfile(self.allocator, self.connection, profile_name);
    }

    pub fn selectTargets(self: *const Self) ![]Target {
        return retrieveTargets(self.allocator, self.connection);
    }

    pub fn linkElement(self: *const Self, element: Element, profile: Profile) !void {
        try db.insertProfileElement(self.connection, element, profile);
    }
};
