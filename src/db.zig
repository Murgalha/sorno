const std = @import("std");
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
pub const __mode_t = c_uint;

pub const Array = extern struct {
    data: ?*anyopaque,
    len: c_uint,
};

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

    sql = @intToPtr([*c]u8, @ptrToInt("CREATE TABLE IF NOT EXISTS profile(name TEXT PRIMARY KEY);"));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    sql = @intToPtr([*c]u8, @ptrToInt("CREATE TABLE IF NOT EXISTS target(name TEXT PRIMARY KEY,path TEXT NOT NULL,address TEXT,user TEXT);"));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    sql = @intToPtr([*c]u8, @ptrToInt("CREATE TABLE IF NOT EXISTS element(name TEXT PRIMARY KEY NOT NULL,source TEXT NOT NULL,destination TEXT NOT NULL);"));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    sql = @intToPtr([*c]u8, @ptrToInt("CREATE TABLE IF NOT EXISTS profileelements(profile TEXT NOT NULL,element TEXT NOT NULL,FOREIGN KEY(profile) REFERENCES profile(name),FOREIGN KEY(element) REFERENCES element(name),PRIMARY KEY(profile, element));"));
    rc = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
}

pub fn db_select_targets(arg_db: ?*sqlite3, arg_n: [*c]c_int) [*c]cTarget {
    var db = arg_db;
    var n = arg_n;
    var arr: Array = Array{
        .data = @intToPtr(?*anyopaque, @as(c_int, 0)),
        .len = @bitCast(c_uint, @as(c_int, 0)),
    };
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = @intToPtr([*c]u8, @ptrToInt("SELECT * FROM target;"));
    _ = c.sqlite3_exec(db, sql, db_select_target_callback, @ptrCast(?*anyopaque, &arr), &errmsg);
    var t: [*c]cTarget = @ptrCast([*c]cTarget, @alignCast(@import("std").meta.alignment(cTarget), arr.data));
    n.* = @bitCast(c_int, arr.len);
    return t;
}

pub fn db_select_profile_names(arg_db: ?*sqlite3, arg_n: [*c]c_int) [*c]cProfile {
    var db = arg_db;
    var n = arg_n;
    var arr: Array = Array{
        .data = @intToPtr(?*anyopaque, @as(c_int, 0)),
        .len = @bitCast(c_uint, @as(c_int, 0)),
    };
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = @intToPtr([*c]u8, @ptrToInt("SELECT * FROM profile;"));
    _ = c.sqlite3_exec(db, sql, db_select_profile_name_callback, @ptrCast(?*anyopaque, &arr), &errmsg);
    var p: [*c]cProfile = @ptrCast([*c]cProfile, @alignCast(@import("std").meta.alignment(cProfile), arr.data));
    p.*.n_elements = 0;
    p.*.element = null;
    n.* = @bitCast(c_int, arr.len);
    return p;
}

pub fn db_select_unlinked_elements(arg_db: ?*sqlite3, arg_n: [*c]c_int) [*c]cElement {
    var db = arg_db;
    var n = arg_n;
    var arr: Array = Array{
        .data = @intToPtr(?*anyopaque, @as(c_int, 0)),
        .len = @bitCast(c_uint, @as(c_int, 0)),
    };
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = @intToPtr([*c]u8, @ptrToInt("SELECT * FROM element WHERE name NOT IN(SELECT element FROM profileelements)"));
    _ = c.sqlite3_exec(db, sql, db_select_element_callback, @ptrCast(?*anyopaque, &arr), &errmsg);
    var e: [*c]cElement = @ptrCast([*c]cElement, @alignCast(@import("std").meta.alignment(cElement), arr.data));
    n.* = @bitCast(c_int, arr.len);
    return e;
}

pub fn db_select_profile(arg_db: ?*sqlite3, arg_profile_name: [*c]u8) [*c]cProfile {
    var db = arg_db;
    var profile_name = arg_profile_name;
    var arr: Array = Array{
        .data = @intToPtr(?*anyopaque, @as(c_int, 0)),
        .len = @bitCast(c_uint, @as(c_int, 0)),
    };
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = c.sqlite3_mprintf("SELECT * FROM element as e JOIN profileelements as pe ON e.name = pe.element WHERE pe.profile = %Q;", profile_name);
    _ = c.sqlite3_exec(db, sql, db_select_element_callback, @ptrCast(?*anyopaque, &arr), &errmsg);
    var prof: [*c]cProfile = @ptrCast([*c]cProfile, @alignCast(@import("std").meta.alignment(cProfile), malloc(@sizeOf(cProfile))));
    prof.*.name = c.mtbs_new(profile_name);
    prof.*.element = @ptrCast([*c]cElement, @alignCast(@import("std").meta.alignment(cElement), arr.data));
    prof.*.n_elements = @intCast(c_int, arr.len);
    return prof;
}

pub fn db_insert_profile(arg_db: ?*sqlite3, arg_p: [*c]cProfile) !void {
    var db = arg_db;
    var p = arg_p;
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = c.sqlite3_mprintf("INSERT INTO profile VALUES(%Q);", p.*.name);
    if (!(sql != null)) {
        try stdout.print("Could not generate INSERT INTO PROFILE query string\n", .{});
    }
    _ = c.sqlite3_exec(db, sql, null, null, &errmsg);
    c.sqlite3_free(@ptrCast(?*anyopaque, errmsg));
    c.sqlite3_free(@ptrCast(?*anyopaque, sql));
}

pub fn db_insert_element(arg_db: ?*sqlite3, arg_e: [*c]cElement) !void {
    var db = arg_db;
    var e = arg_e;
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = c.sqlite3_mprintf("INSERT INTO element VALUES(%Q, %Q, %Q);", e.*.name, e.*.source, e.*.destination);
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

pub fn db_insert_target(arg_db: ?*sqlite3, arg_t: [*c]cTarget) !void {
    var db = arg_db;
    var t = arg_t;
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = c.sqlite3_mprintf("INSERT INTO target VALUES(%Q, %Q, %Q, %Q);", t.*.name, t.*.path, t.*.address, t.*.user);
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

pub fn db_link_element(arg_db: ?*sqlite3, arg_e: [*c]cElement, arg_p: [*c]cProfile) !void {
    var db = arg_db;
    var e = arg_e;
    var p = arg_p;
    var errmsg: [*c]u8 = undefined;
    var sql: [*c]u8 = c.sqlite3_mprintf("INSERT INTO profileelements VALUES(%Q, %Q);", p.*.name, e.*.name);
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

pub fn db_select_target_callback(arg_arr: ?*anyopaque, arg_ncols: c_int, arg_columns: [*c][*c]u8, arg_names: [*c][*c]u8) callconv(.C) c_int {
    var arr = arg_arr;
    var ncols = arg_ncols;
    var columns = arg_columns;
    var names = arg_names;
    var array: [*c]Array = @ptrCast([*c]Array, @alignCast(@import("std").meta.alignment(Array), arr));
    var t: [*c]cTarget = @ptrCast([*c]cTarget, @alignCast(@import("std").meta.alignment(cTarget), array.*.data));
    var len: [*c]c_uint = &array.*.len;
    t = @ptrCast([*c]cTarget, @alignCast(@import("std").meta.alignment(Target), c.realloc(@ptrCast(?*anyopaque, t), @sizeOf(Target) *% @bitCast(c_ulong, @as(c_ulong, len.* +% @bitCast(c_uint, @as(c_int, 1)))))));
    {
        var i: c_int = 0;
        while (i < ncols) : (i += 1) {
            if (!(c.strcmp((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk names + @intCast(usize, tmp) else break :blk names - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
            }).*, "name") != 0)) {
                t[len.*].name = c.mtbs_new((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk columns + @intCast(usize, tmp) else break :blk columns - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*);
            } else if (!(c.strcmp((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk names + @intCast(usize, tmp) else break :blk names - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
            }).*, "path") != 0)) {
                t[len.*].path = c.mtbs_new((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk columns + @intCast(usize, tmp) else break :blk columns - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*);
            } else if (!(c.strcmp((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk names + @intCast(usize, tmp) else break :blk names - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
            }).*, "address") != 0)) {
                t[len.*].address = c.mtbs_new((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk columns + @intCast(usize, tmp) else break :blk columns - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*);
            } else if (!(c.strcmp((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk names + @intCast(usize, tmp) else break :blk names - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
            }).*, "user") != 0)) {
                t[len.*].user = c.mtbs_new((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk columns + @intCast(usize, tmp) else break :blk columns - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*);
            }
        }
    }
    len.* +%= 1;
    array.*.data = @ptrCast(?*anyopaque, t);
    return 0;
}

pub fn db_select_profile_name_callback(arg_arr: ?*anyopaque, arg_ncols: c_int, arg_columns: [*c][*c]u8, arg_names: [*c][*c]u8) callconv(.C) c_int {
    var arr = arg_arr;
    var ncols = arg_ncols;
    var columns = arg_columns;
    var names = arg_names;
    _ = names;
    var array: [*c]Array = @ptrCast([*c]Array, @alignCast(@import("std").meta.alignment(Array), arr));
    var p: [*c]cProfile = @ptrCast([*c]cProfile, @alignCast(@import("std").meta.alignment(cProfile), array.*.data));
    var len: [*c]c_uint = &array.*.len;
    p = @ptrCast([*c]cProfile, @alignCast(@import("std").meta.alignment(Profile), c.realloc(@ptrCast(?*anyopaque, p), @sizeOf(cProfile) *% @bitCast(c_ulong, @as(c_ulong, len.* +% @bitCast(c_uint, @as(c_int, 1)))))));
    {
        var i: c_int = 0;
        while (i < ncols) : (i += 1) {
            p[len.*].name = c.mtbs_new((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk columns + @intCast(usize, tmp) else break :blk columns - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
            }).*);
        }
    }
    len.* +%= 1;
    array.*.data = @ptrCast(?*anyopaque, p);
    return 0;
}

pub fn db_select_element_callback(arg_arr: ?*anyopaque, arg_ncols: c_int, arg_columns: [*c][*c]u8, arg_names: [*c][*c]u8) callconv(.C) c_int {
    var arr = arg_arr;
    var ncols = arg_ncols;
    var columns = arg_columns;
    var names = arg_names;
    var array: [*c]Array = @ptrCast([*c]Array, @alignCast(@import("std").meta.alignment(Array), arr));
    var e: [*c]cElement = @ptrCast([*c]cElement, @alignCast(@import("std").meta.alignment(cElement), array.*.data));
    var len: [*c]c_uint = &array.*.len;
    e = @ptrCast([*c]cElement, @alignCast(@import("std").meta.alignment(cElement), c.realloc(@ptrCast(?*anyopaque, e), @sizeOf(cElement) *% @bitCast(c_ulong, @as(c_ulong, len.* +% @bitCast(c_uint, @as(c_int, 1)))))));
    {
        var i: c_int = 0;
        while (i < ncols) : (i += 1) {
            if (!(c.strcmp((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk names + @intCast(usize, tmp) else break :blk names - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
            }).*, "name") != 0)) {
                e[len.*].name = c.mtbs_new((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk columns + @intCast(usize, tmp) else break :blk columns - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*);
            } else if (!(c.strcmp((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk names + @intCast(usize, tmp) else break :blk names - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
            }).*, "source") != 0)) {
                e[len.*].source = c.mtbs_new((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk columns + @intCast(usize, tmp) else break :blk columns - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*);
            } else if (!(c.strcmp((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk names + @intCast(usize, tmp) else break :blk names - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
            }).*, "destination") != 0)) {
                e[len.*].destination = c.mtbs_new((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk columns + @intCast(usize, tmp) else break :blk columns - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*);
            }
        }
    }
    len.* +%= 1;
    array.*.data = @ptrCast(?*anyopaque, e);
    return 0;
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
