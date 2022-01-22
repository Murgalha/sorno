const std = @import("std");
const mem = std.mem;
const c = @import("c.zig");
const sqlite3 = c.sqlite3;
const free = c.free;
const malloc = c.malloc;
const fgetc = c.fgetc;
const FILE = c.FILE;
const data = @import("data.zig");
const Element = data.Element;
const Profile = data.Profile;
const Target = data.Target;
const cElement = data.cElement;
const cProfile = data.cProfile;
const cTarget = data.cTarget;
const stdout = std.io.getStdOut().writer();
const qStrings = @import("query_strings.zig");
const cb = @import("callbacks.zig");
const ArrayList = std.ArrayList;
const utils = @import("utils.zig");

pub const __mode_t = c_uint;

pub fn db_get_path() [*c]u8 {
    var data_dir: [*c]u8 = c.getenv("XDG_DATA_HOME");
    var path: [*c]u8 = undefined;
    if (data_dir != null) {
        path = c.mtbs_join(@as(c_int, 2), data_dir, "/sorno/db");
    } else {
        data_dir = c.getenv("HOME");
        path = c.mtbs_join(@as(c_int, 2), data_dir, "/.local/share/sorno/db");
    }
    return path;
}

pub fn db_open() !?*sqlite3 {
    var path: [*c]u8 = db_get_path();
    var db_name: [*c]u8 = c.mtbs_join(@as(c_int, 2), path, "/sorno.db");
    try mkdir_p(path);
    var db: ?*sqlite3 = undefined;
    var res: c_int = c.sqlite3_open(db_name, &db);
    if (res != @as(c_int, 0)) {
        try stdout.print("Could not open database connection: {s}\n", .{c.sqlite3_errmsg(db)});
    }
    db_create_tables(db);
    free(@ptrCast(?*anyopaque, path));
    free(@ptrCast(?*anyopaque, db_name));
    return db;
}

pub fn db_close(arg_db: ?*sqlite3) void {
    var db = arg_db;
    _ = c.sqlite3_close(db);
}

pub fn db_create_tables(arg_db: ?*sqlite3) void {
    var db = arg_db;
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

pub fn retrieveFullProfile(allocator: *const mem.Allocator, db: ?*sqlite3, profile_name: []u8) Profile {
    // TODO: Retrieve profile based on ID, not name
    var list = ArrayList(Profile).init(allocator.*);
    defer list.deinit();

    var errmsg: [*c]u8 = undefined;
    var name = c.mtbs_new_size(@ptrCast([*c]u8, profile_name.ptr), @intCast(c_int, profile_name.len));
    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.SELECT_FULL_PROFILE, name);

    _ = c.sqlite3_exec(db, sql, cb.selectProfileCallback, @ptrCast(?*anyopaque, &list), &errmsg);

    var slice = list.toOwnedSlice();

    std.debug.assert(slice.len == 1);

    return slice[0];
}

pub fn insertProfileElement(db: ?*sqlite3, element: Element, profile: Profile) !void {
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_PROFILEELEMENT, profile.id, element.id);

    if (!(sql != null)) {
        try stdout.print("Could not generate INSERT INTO PROFILEELEMENTS query string\n", .{});
        c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
        c.sqlite3_free(@ptrCast(?*anyopaque, sql));
        return;
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    c.sqlite3_free(@ptrCast(?*anyopaque, sql));
}

pub fn insertProfile(arg_db: ?*sqlite3, arg_p: Profile) !void {
    var db = arg_db;
    var p = arg_p;
    var errmsg: [*c]u8 = undefined;

    var name = c.mtbs_new_size(@ptrCast([*c]u8, p.name.ptr), @intCast(c_int, p.name.len));
    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_PROFILE, name);
    if (!(sql != null)) {
        try stdout.print("Could not generate INSERT INTO PROFILE query string\n", .{});
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    c.sqlite3_free(@ptrCast(?*anyopaque, sql));
}

pub fn insertElement(arg_db: ?*sqlite3, arg_e: Element) !void {
    var db = arg_db;
    var e = arg_e;
    var errmsg: [*c]u8 = undefined;

    var name = c.mtbs_new_size(@ptrCast([*c]u8, e.name.ptr), @intCast(c_int, e.name.len));
    var source = c.mtbs_new_size(@ptrCast([*c]u8, e.source.ptr), @intCast(c_int, e.source.len));
    var destination = c.mtbs_new_size(@ptrCast([*c]u8, e.destination.ptr), @intCast(c_int, e.destination.len));
    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_ELEMENT, name, source, destination);
    if (!(sql != null)) {
        try stdout.print("Could not generate INSERT INTO ELEMENT query string\n", .{});
        c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
        c.sqlite3_free(@ptrCast(?*anyopaque, sql));
        return;
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    c.sqlite3_free(@ptrCast(?*anyopaque, sql));
}

pub fn insertTarget(arg_db: ?*sqlite3, arg_t: Target) !void {
    var db = arg_db;
    var t = arg_t;
    var errmsg: [*c]u8 = undefined;

    var name = c.mtbs_new_size(@ptrCast([*c]u8, t.name.ptr), @intCast(c_int, t.name.len));
    var path = c.mtbs_new_size(@ptrCast([*c]u8, t.path.ptr), @intCast(c_int, t.path.len));
    var address = c.mtbs_new_size(@ptrCast([*c]u8, t.address.ptr), @intCast(c_int, t.address.len));
    var user = c.mtbs_new_size(@ptrCast([*c]u8, t.user.ptr), @intCast(c_int, t.user.len));
    var sql: [*c]u8 = c.sqlite3_mprintf(qStrings.INSERT_TARGET, name, path, address, user);
    if (!(sql != null)) {
        try stdout.print("Could not generate INSERT INTO TARGET query string\n", .{});
        c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
        c.sqlite3_free(@ptrCast(?*anyopaque, sql));
        return;
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    c.sqlite3_free(@ptrCast(?*anyopaque, sql));
}

pub fn mkdir_p(arg_path: [*c]u8) !void {
    var path = arg_path;
    var n: c_int = undefined;
    var tokens: [*c][*c]u8 = c.mtbs_split(path, &n, @intToPtr([*c]u8, @ptrToInt("/")));
    var full_path: [*c]u8 = c.mtbs_new(@intToPtr([*c]u8, @ptrToInt("/")));
    {
        var i: c_int = 0;
        while (i < n) : (i += 1) {
            c.mtbs_concat(@as(c_int, 3), &full_path, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk tokens + @intCast(usize, tmp) else break :blk tokens - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
            }).*, "/");
            var dir: ?*c.DIR = c.opendir(full_path);
            if (dir != null) {
                _ = c.closedir(dir);
            } else if (@as(c_int, 2) == c.__errno_location().*) {
                _ = c.mkdir(full_path, @bitCast(__mode_t, @as(c_int, 511)));
            } else {
                try stdout.print("Could not create directory {s}\n", .{full_path});
            }
        }
    }
    free(@ptrCast(?*anyopaque, full_path));
    c.mtbs_free_split(tokens, n);
}
