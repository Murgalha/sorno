const std = @import("std");
const c = @import("c.zig");
const ArrayList = std.ArrayList;
const log = std.log;

const SqliteError = error{};

pub const SqliteRow = struct {
    cells: []const SqliteCell,
};

pub const SqliteCell = struct {
    name: []const u8,
    value: []const u8,
};

const CallbackData = struct {
    allocator: *const std.mem.Allocator,
    userData: ?*anyopaque,
    userCallback: *const fn (*const std.mem.Allocator, SqliteRow, ?*anyopaque) i32,
};

pub const SqliteDb = struct { data: ?*c.sqlite3 };

pub fn openConnection(path: []u8) SqliteDb {
    var db: ?*c.sqlite3 = undefined;
    const res: c_int = c.sqlite3_open(@ptrCast(path), &db);
    if (res != 0) {
        log.err("Could not open database connection on '{s}': {s}\n", .{ path, c.sqlite3_errmsg(db) });
        std.process.exit(1);
    }

    return SqliteDb{ .data = db };
}

pub fn closeConnection(db: SqliteDb) void {
    const res: c_int = c.sqlite3_close(db.data);

    if (res != 0) {
        log.err("Could not close database connection: {s}\n", .{c.sqlite3_errmsg(db)});
        std.process.exit(1);
    }
}

pub fn execute(database: SqliteDb, query: []const u8) i32 {
    var rc: c_int = undefined;
    var errmsg: [*c]u8 = undefined;

    const sql: [*c]u8 = @constCast(@ptrCast(query));
    rc = c.sqlite3_exec(database.data, sql, null, null, &errmsg);
    if (rc != 0) {
        log.err("Error {d} while executing statement: {s}\n", .{ rc, errmsg });
    }
    c.sqlite3_free(@ptrCast(errmsg));

    return rc;
}

pub fn executeWithCallback(allocator: *const std.mem.Allocator, database: SqliteDb, query: []const u8, callback: *const fn (*const std.mem.Allocator, SqliteRow, ?*anyopaque) i32, data: ?*anyopaque) i32 {
    var errmsg: [*c]u8 = undefined;

    var callbackData = CallbackData{ .allocator = allocator, .userData = data, .userCallback = callback };

    const sql: [*c]u8 = @constCast(@ptrCast(query));
    _ = c.sqlite3_exec(database.data, sql, internalCallback, @ptrCast(&callbackData), &errmsg);

    // TODO: Handle error message
    c.sqlite3_free(@ptrCast(errmsg));

    return 0;
}

fn internalCallback(ptr: ?*anyopaque, ncols: c_int, columns: [*c][*c]u8, names: [*c][*c]u8) callconv(.C) c_int {
    const callbackData: *CallbackData = @ptrCast(@alignCast(ptr));

    var list = ArrayList(SqliteCell).init(callbackData.allocator.*);
    defer list.deinit();

    var i: usize = 0;
    while (i < ncols) : (i += 1) {
        list.append(SqliteCell{ .name = std.mem.span(names[i]), .value = std.mem.span(columns[i]) }) catch {
            return -1;
        };
    }

    const row = SqliteRow{ .cells = list.toOwnedSlice() catch {
        return -1;
    } };

    return callbackData.userCallback(callbackData.allocator, row, callbackData.userData);
}
