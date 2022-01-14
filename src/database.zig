const std = @import("std");
const c = @import("c.zig");
const db = @import("db.zig");
const sqlite3 = c.sqlite3;
const Element = @import("data.zig").Element;
const Target = @import("data.zig").Target;
const Profile = @import("data.zig").Profile;
const toCTarget = @import("data.zig").toCTarget;
const toCProfile = @import("data.zig").toCProfile;
const toCElement = @import("data.zig").toCElement;
const fromCTarget = @import("data.zig").fromCTarget;
const fromCProfile = @import("data.zig").fromCProfile;
const fromCElement = @import("data.zig").fromCElement;
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
                var e = toCElement(data);
                try db.db_insert_element(self.connection, e);
            },
            Profile => {
                var p = toCProfile(data);
                try db.db_insert_profile(self.connection, p);
            },
            Target => {
                var t = toCTarget(data);
                try db.db_insert_target(self.connection, t);
            },
            else => {
                return DatabaseError.InvalidType;
            },
        }
    }

    pub fn selectUnlinkedElements(self: *const Self) ![]Element {
        var n: c_int = undefined;
        var elements = db.db_select_unlinked_elements(self.connection, &n);
        var list = ArrayList(Element).init(self.allocator.*);
        defer list.deinit();

        var i: usize = 0;
        while (i < n) : (i += 1) {
            try list.append(fromCElement(elements[0]));
        }

        return list.toOwnedSlice();
    }

    pub fn selectProfileNames(self: *const Self) ![]Profile {
        var n: c_int = undefined;
        var profiles = db.db_select_profile_names(self.connection, &n);
        var list = ArrayList(Profile).init(self.allocator.*);
        defer list.deinit();

        var i: usize = 0;
        while (i < n) : (i += 1) {
            try list.append(try fromCProfile(self.allocator, profiles[0]));
        }

        return list.toOwnedSlice();
    }

    pub fn selectProfile(self: *const Self, profile_name: []u8) !Profile {
        var name = @ptrCast([*c]u8, profile_name.ptr);
        var p = db.db_select_profile(self.connection, name).*;
        var profile = fromCProfile(self.allocator, p);

        return profile;
    }

    pub fn selectTargets(self: *const Self) ![]Target {
        var n: c_int = undefined;
        var targets = db.db_select_targets(self.connection, &n);
        var list = ArrayList(Target).init(self.allocator.*);
        defer list.deinit();

        var i: usize = 0;
        while (i < n) : (i += 1) {
            try list.append(fromCTarget(targets[0]));
        }

        return list.toOwnedSlice();
    }

    pub fn linkElement(self: *const Self, element: Element, profile: Profile) !void {
        var e = toCElement(element);
        var p = toCProfile(profile);

        try db.db_link_element(self.connection, e, p);
    }
};
