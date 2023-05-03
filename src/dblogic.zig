const std = @import("std");
const c = @import("c.zig");
const qStrings = @import("querystrings.zig");
const cb = @import("callbacks.zig");
const dm = @import("datamodels.zig");
const utils = @import("utils.zig");
const log = std.log;
const cstr = std.cstr;
const mem = std.mem;
const sqlite3 = c.sqlite3;
const free = c.free;
const malloc = c.malloc;
const fgetc = c.fgetc;
const FILE = c.FILE;
const Element = dm.Element;
const Profile = dm.Profile;
const Target = dm.Target;
const stdout = std.io.getStdOut().writer();
const ArrayList = std.ArrayList;

pub const __mode_t = c_uint;

pub fn openConnection(allocator: *const mem.Allocator, path: []u8) !?*sqlite3 {
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    try list.appendSlice(path);
    try list.appendSlice("/sorno.db");

    try createPath(allocator, path);
    var db_name = try list.toOwnedSliceSentinel(0);

    var db: ?*sqlite3 = undefined;
    var res: c_int = c.sqlite3_open(db_name, &db);
    if (res != @as(c_int, 0)) {
        log.err("Could not open database connection on '{s}': {s}\n", .{ db_name, c.sqlite3_errmsg(db) });
        std.process.exit(1);
    }

    createAllTables(db);

    return db;
}

pub fn closeConnection(db: ?*sqlite3) void {
    _ = c.sqlite3_close(db);
}

pub fn createAllTables(db: ?*sqlite3) void {
    var rc: c_int = undefined;
    var sql: [*c]u8 = undefined;
    var errmsg: [*c]u8 = undefined;

    sql = @intToPtr([*c]u8, @ptrToInt(qStrings.CREATE_PROFILE_TABLE));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    if (rc != 0) {
        std.debug.print("Error {d}: {s}\n", .{ rc, errmsg });
    }
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));

    sql = @intToPtr([*c]u8, @ptrToInt(qStrings.CREATE_TARGET_TABLE));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    if (rc != 0) {
        std.debug.print("Error {d}: {s}\n", .{ rc, errmsg });
    }
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));

    sql = @intToPtr([*c]u8, @ptrToInt(qStrings.CREATE_ELEMENT_TABLE));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    if (rc != 0) {
        std.debug.print("Error {d}: {s}\n", .{ rc, errmsg });
    }
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));

    sql = @intToPtr([*c]u8, @ptrToInt(qStrings.CREATE_PROFILEELEMENTS_TABLE));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    if (rc != 0) {
        std.debug.print("Error {d}: {s}\n", .{ rc, errmsg });
    }
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
}

pub fn retrieveTargets(allocator: *const mem.Allocator, db: ?*sqlite3) []Target {
    var list = ArrayList(Target).init(allocator.*);
    defer list.deinit();

    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = @intToPtr([*c]u8, @ptrToInt(qStrings.SELECT_ALL_TARGETS));
    _ = c.sqlite3_exec(db, sql, cb.selectTargetCallback, @ptrCast(?*anyopaque, &list), &errmsg);

    return list.toOwnedSlice();
}

pub fn retrieveProfileNames(allocator: *const mem.Allocator, db: ?*sqlite3) []Profile {
    var list = ArrayList(Profile).init(allocator.*);
    defer list.deinit();

    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = @intToPtr([*c]u8, @ptrToInt(qStrings.SELECT_ALL_PROFILE_NAMES));
    _ = c.sqlite3_exec(db, sql, cb.selectProfileNameCallback, @ptrCast(?*anyopaque, &list), &errmsg);

    return list.toOwnedSlice();
}

pub fn retrieveUnlinkedElements(allocator: *const mem.Allocator, db: ?*sqlite3) []Element {
    var list = ArrayList(Element).init(allocator.*);
    defer list.deinit();

    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = @intToPtr([*c]u8, @ptrToInt(qStrings.SELECT_UNLINKED_ELEMENTS));
    _ = c.sqlite3_exec(db, sql, cb.selectElementCallback, @ptrCast(?*anyopaque, &list), &errmsg);

    return list.toOwnedSlice();
}

pub fn retrieveFullProfile(allocator: *const mem.Allocator, db: ?*sqlite3, profile_name: []u8) !Profile {
    // TODO: Retrieve profile based on ID, not name
    var list = ArrayList(Profile).init(allocator.*);
    defer list.deinit();

    var errmsg: [*c]u8 = undefined;
    var name = @ptrCast([*c]u8, try cstr.addNullByte(allocator.*, profile_name));
    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.SELECT_FULL_PROFILE, name);

    _ = c.sqlite3_exec(db, sql, cb.selectProfileCallback, @ptrCast(?*anyopaque, &list), &errmsg);

    var slice = list.toOwnedSlice();

    std.debug.assert(slice.len == 1);

    return slice[0];
}

pub fn insertProfileElement(_: *const mem.Allocator, db: ?*sqlite3, element: Element, profile: Profile) !void {
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_PROFILEELEMENT, profile.id, element.id);

    if (sql == null) {
        try stdout.print("Could not generate INSERT INTO PROFILEELEMENTS query string\n", .{});
        c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
        c.sqlite3_free(@ptrCast(?*anyopaque, sql));
        return;
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    c.sqlite3_free(@ptrCast(?*anyopaque, sql));
}

pub fn insertProfile(allocator: *const mem.Allocator, db: ?*sqlite3, p: Profile) !void {
    var errmsg: [*c]u8 = undefined;

    var name = try cstr.addNullByte(allocator.*, p.name);
    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_PROFILE, @ptrCast([*c]u8, name));
    if (sql == null) {
        try stdout.print("Could not generate INSERT INTO PROFILE query string\n", .{});
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    c.sqlite3_free(@ptrCast(?*anyopaque, sql));
}

pub fn insertElement(allocator: *const mem.Allocator, db: ?*sqlite3, e: Element) !void {
    var errmsg: [*c]u8 = undefined;

    var name = @ptrCast([*c]u8, try cstr.addNullByte(allocator.*, e.name));
    var source = @ptrCast([*c]u8, try cstr.addNullByte(allocator.*, e.source));
    var destination = @ptrCast([*c]u8, try cstr.addNullByte(allocator.*, e.destination));

    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_ELEMENT, name, source, destination);
    if (sql == null) {
        try stdout.print("Could not generate INSERT INTO ELEMENT query string\n", .{});
        c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
        c.sqlite3_free(@ptrCast(?*anyopaque, sql));
        return;
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    c.sqlite3_free(@ptrCast(?*anyopaque, sql));
}

pub fn insertTarget(allocator: *const mem.Allocator, db: ?*sqlite3, t: Target) !void {
    var errmsg: [*c]u8 = undefined;

    var name = @ptrCast([*c]u8, try cstr.addNullByte(allocator.*, t.name));
    var path = @ptrCast([*c]u8, try cstr.addNullByte(allocator.*, t.path));
    var address = @ptrCast([*c]u8, try cstr.addNullByte(allocator.*, t.address));
    var user = @ptrCast([*c]u8, try cstr.addNullByte(allocator.*, t.user));
    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_TARGET, name, path, address, user);
    if (sql == null) {
        try stdout.print("Could not generate INSERT INTO TARGET query string\n", .{});
        c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
        c.sqlite3_free(@ptrCast(?*anyopaque, sql));
        return;
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    c.sqlite3_free(@ptrCast(?*anyopaque, sql));
}

pub fn createPath(allocator: *const mem.Allocator, path: []u8) !void {
    var indexes = try utils.getDelimIndexes(allocator, path, '/');
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    var start: usize = 0;
    for (indexes) |index| {
        var partial_path = path[start..index];

        try list.appendSlice(partial_path);

        var fullpath = try cstr.addNullByte(allocator.*, list.items);

        var dir: ?*c.DIR = c.opendir(fullpath);
        if (dir != null) {
            _ = c.closedir(dir);
        } else if (@as(c_int, 2) == c.__errno_location().*) {
            _ = c.mkdir(fullpath, @bitCast(__mode_t, @as(c_int, 511)));
        } else {
            try stdout.print("Could not create directory {s}\n", .{fullpath});
        }

        start = index;
    }
}
