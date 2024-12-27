const std = @import("std");
const c = @import("c.zig");
const qStrings = @import("querystrings.zig");
const cb = @import("callbacks.zig");
const dm = @import("datamodels.zig");
const utils = @import("utils.zig");
const log = std.log;
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

pub fn openConnection(allocator: *const mem.Allocator, path: []u8) !?*sqlite3 {
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    try list.appendSlice(path);
    try list.appendSlice("/sorno.db");

    try createPath(allocator, path);
    const db_name = try list.toOwnedSliceSentinel(0);

    var db: ?*sqlite3 = undefined;
    const res: c_int = c.sqlite3_open(db_name, &db);
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
    var errmsg: [*c]u8 = undefined;

    var sql: [*c]u8 = @constCast(@ptrCast(qStrings.CREATE_PROFILE_TABLE));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    if (rc != 0) {
        std.debug.print("Error {d}: {s}\n", .{ rc, errmsg });
    }
    c.sqlite3_free(@ptrCast(errmsg));

    sql = @constCast(@ptrCast(qStrings.CREATE_TARGET_TABLE));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    if (rc != 0) {
        std.debug.print("Error {d}: {s}\n", .{ rc, errmsg });
    }
    c.sqlite3_free(@ptrCast(errmsg));

    sql = @constCast(qStrings.CREATE_ELEMENT_TABLE);
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    if (rc != 0) {
        std.debug.print("Error {d}: {s}\n", .{ rc, errmsg });
    }
    c.sqlite3_free(@ptrCast(errmsg));

    sql = @constCast(qStrings.CREATE_PROFILEELEMENTS_TABLE);
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    if (rc != 0) {
        std.debug.print("Error {d}: {s}\n", .{ rc, errmsg });
    }
    c.sqlite3_free(@ptrCast(errmsg));
}

pub fn retrieveTargets(allocator: *const mem.Allocator, db: ?*sqlite3) ![]Target {
    var list = ArrayList(Target).init(allocator.*);
    defer list.deinit();

    var errmsg: [*c]u8 = undefined;
    const sql: [*c]u8 = @constCast(@ptrCast(qStrings.SELECT_ALL_TARGETS));
    _ = c.sqlite3_exec(db, sql, cb.selectTargetCallback, @ptrCast(&list), &errmsg);

    return try list.toOwnedSlice();
}

pub fn retrieveProfileNames(allocator: *const mem.Allocator, db: ?*sqlite3) ![]Profile {
    var list = ArrayList(Profile).init(allocator.*);
    defer list.deinit();

    var errmsg: [*c]u8 = undefined;
    const sql: [*c]u8 = @constCast(@ptrCast(qStrings.SELECT_ALL_PROFILE_NAMES));
    _ = c.sqlite3_exec(db, sql, cb.selectProfileNameCallback, @ptrCast(&list), &errmsg);

    return try list.toOwnedSlice();
}

pub fn retrieveUnlinkedElements(allocator: *const mem.Allocator, db: ?*sqlite3) ![]Element {
    var list = ArrayList(Element).init(allocator.*);
    defer list.deinit();

    var errmsg: [*c]u8 = undefined;
    const sql: [*c]u8 = @constCast(@ptrCast(qStrings.SELECT_UNLINKED_ELEMENTS));
    _ = c.sqlite3_exec(db, sql, cb.selectElementCallback, @ptrCast(&list), &errmsg);

    return try list.toOwnedSlice();
}

pub fn retrieveFullProfile(allocator: *const mem.Allocator, db: ?*sqlite3, profile_name: []u8) !Profile {
    // TODO: Retrieve profile based on ID, not name
    var list = ArrayList(Profile).init(allocator.*);
    defer list.deinit();

    var errmsg: [*c]u8 = undefined;
    const name: [*c]u8 = @ptrCast(try allocator.*.dupeZ(u8, profile_name));
    const sql: [*c]u8 = c.sqlite3_mprintf(qStrings.SELECT_FULL_PROFILE, name);

    _ = c.sqlite3_exec(db, sql, cb.selectProfileCallback, @ptrCast(&list), &errmsg);

    const slice = try list.toOwnedSlice();

    std.debug.assert(slice.len == 1);

    return slice[0];
}

pub fn insertProfileElement(_: *const mem.Allocator, db: ?*sqlite3, element: Element, profile: Profile) !void {
    var errmsg: [*c]u8 = undefined;
    const sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_PROFILEELEMENT, profile.id, element.id);

    if (sql == null) {
        try stdout.print("Could not generate INSERT INTO PROFILEELEMENTS query string\n", .{});
        c.sqlite3_free(@ptrCast(errmsg));
        c.sqlite3_free(@ptrCast(sql));
        return;
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(errmsg));
    c.sqlite3_free(@ptrCast(sql));
}

pub fn insertProfile(allocator: *const mem.Allocator, db: ?*sqlite3, p: Profile) !void {
    var errmsg: [*c]u8 = undefined;

    const name = try allocator.*.dupeZ(u8, p.name);
    const sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_PROFILE, @as([*c]u8, name));
    if (sql == null) {
        try stdout.print("Could not generate INSERT INTO PROFILE query string\n", .{});
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(errmsg));
    c.sqlite3_free(@ptrCast(sql));
}

pub fn insertElement(allocator: *const mem.Allocator, db: ?*sqlite3, e: Element) !void {
    var errmsg: [*c]u8 = undefined;

    const name: [*c]u8 = @ptrCast(try allocator.*.dupeZ(u8, e.name));
    const source: [*c]u8 = @ptrCast(try allocator.*.dupeZ(u8, e.source));
    const destination: [*c]u8 = @ptrCast(try allocator.*.dupeZ(u8, e.destination));

    const sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_ELEMENT, name, source, destination);
    if (sql == null) {
        try stdout.print("Could not generate INSERT INTO ELEMENT query string\n", .{});
        c.sqlite3_free(@ptrCast(errmsg));
        c.sqlite3_free(@ptrCast(sql));
        return;
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(errmsg));
    c.sqlite3_free(@ptrCast(sql));
}

pub fn insertTarget(allocator: *const mem.Allocator, db: ?*sqlite3, t: Target) !void {
    var errmsg: [*c]u8 = undefined;

    const name: [*c]u8 = @ptrCast(try allocator.*.dupeZ(u8, t.name));
    const path: [*c]u8 = @ptrCast(try allocator.*.dupeZ(u8, t.path));
    const address: [*c]u8 = @ptrCast(try allocator.*.dupeZ(u8, t.address));
    const user: [*c]u8 = @ptrCast(try allocator.*.dupeZ(u8, t.user));
    const sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_TARGET, name, path, address, user);
    if (sql == null) {
        try stdout.print("Could not generate INSERT INTO TARGET query string\n", .{});
        c.sqlite3_free(@ptrCast(errmsg));
        c.sqlite3_free(@ptrCast(sql));
        return;
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(errmsg));
    c.sqlite3_free(@ptrCast(sql));
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
