const std = @import("std");
const c = @import("c.zig");
const ArrayList = std.ArrayList;
const log = std.log;
const Allocator = std.mem.Allocator;
const StringArrayHashMap = std.array_hash_map.StringArrayHashMap;

const SqliteError = error{};

pub const SqliteRow = struct {
    cells: []const SqliteCell,
};

pub const SqliteCell = struct {
    name: []const u8,
    value: []const u8,
};

const CallbackData = struct {
    allocator: *const Allocator,
    userData: ?*anyopaque,
    userCallback: *const fn (*const Allocator, SqliteRow, ?*anyopaque) i32,
};

pub const Statement = struct {
    const Self = @This();
    stmt: ?*c.sqlite3_stmt,

    pub fn execute(self: *const Self) i32 {
        return c.sqlite3_step(self.stmt);
    }

    pub fn columnCount(self: *const Self) i32 {
        return c.sqlite3_column_count(self.stmt);
    }

    pub fn finalize(self: *const Self) i32 {
        return c.sqlite3_finalize(self.stmt);
    }
};

pub const DbHandle = struct {
    const Self = @This();
    handle: ?*c.sqlite3,

    pub fn init(path: []const u8) Self {
        var db: ?*c.sqlite3 = undefined;
        const dbFlags = c.SQLITE_OPEN_READWRITE | c.SQLITE_OPEN_CREATE;
        const res: c_int = c.sqlite3_open_v2(@ptrCast(path), &db, dbFlags, null);
        if (res != 0) {
            log.err("Could not open database connection on '{s}': {s}\n", .{ path, c.sqlite3_errmsg(db) });
            std.process.exit(1);
        }

        return Self{ .handle = db };
    }

    pub fn deinit(self: *const Self) void {
        const res: c_int = c.sqlite3_close(self.handle);

        if (res != 0) {
            log.err("Could not close database connection: {s}\n", .{c.sqlite3_errmsg(self.handle)});
            std.process.exit(1);
        }
    }

    pub fn execute(self: *const Self, allocator: *const Allocator, query: []const u8, args: anytype) !void {
        var stmt = try self
            .prepareStatement(allocator, query, args);
        defer _ = stmt.finalize();

        const rc = stmt.execute();
        if (rc != c.SQLITE_DONE) {
            std.log.err("Error executing statement {d}: {s}\n", .{ rc, c.sqlite3_errmsg(self.handle) });
        }
    }

    pub fn executeWithReturn(
        self: *const Self,
        allocator: *const Allocator,
        query: []const u8,
        args: anytype,
    ) ![]StringArrayHashMap([]const u8) {
        var stmt = try self
            .prepareStatement(allocator, query, args);
        defer _ = stmt.finalize();

        var list = ArrayList(StringArrayHashMap([]const u8)).init(allocator.*);
        var rc = c.SQLITE_ROW;

        while (true) {
            rc = stmt.execute();
            if (rc == c.SQLITE_DONE) break;

            const colCount = stmt.columnCount();

            var hash_map = StringArrayHashMap([]const u8).init(allocator.*);
            for (0..@intCast(colCount)) |colIndex| {
                const name = try allocator.dupe(u8, std.mem.span(c.sqlite3_column_name(stmt.stmt, @intCast(colIndex))));
                var value: []const u8 = undefined;

                const v = c.sqlite3_column_text(stmt.stmt, @intCast(colIndex));
                if (v == null) {
                    value = &.{};
                } else {
                    value = try allocator.dupe(u8, std.mem.span(v));
                }

                try hash_map.put(name, value);
            }

            try list.append(hash_map);
        }

        return list.toOwnedSlice();
    }

    fn prepareStatement(self: *const Self, allocator: *const Allocator, query: []const u8, args: anytype) !Statement {
        const c_query = try allocator.*.dupeZ(u8, query);
        var stmt: ?*c.sqlite3_stmt = undefined;

        var rc: c_int = undefined;
        rc = c.sqlite3_prepare_v2(self.handle, c_query, -1, @ptrCast(&stmt), null);

        inline for (args, 1..) |arg, idx| {
            self.bindArg(stmt, arg, idx);
        }

        return Statement{ .stmt = stmt };
    }

    fn bindArg(_: *const Self, stmt: ?*c.sqlite3_stmt, arg: anytype, bind_index: i32) void {
        var rc: c_int = undefined;
        const typeInfo = @typeInfo(@TypeOf(arg));

        switch (typeInfo) {
            .Int, .ComptimeInt => {
                rc = c.sqlite3_bind_int64(stmt, bind_index, @intCast(arg));
            },
            .Float, .ComptimeFloat => {
                rc = c.sqlite3_bind_double(stmt, bind_index, arg);
            },
            .Pointer => |ptr| {
                switch (ptr.size) {
                    .One => switch (@typeInfo(ptr.child)) {
                        .Array => |arr| {
                            if (arr.child == u8) {
                                rc = c.sqlite3_bind_text(stmt, bind_index, arg.ptr, @intCast(arg.len), c.SQLITE_STATIC);
                            } else {
                                std.debug.print("Unsupported array type '{any}'", .{@typeInfo(arr.child)});
                            }
                        },
                        else => std.debug.print("Unsupported type '{any}'", .{@typeInfo(@TypeOf(arg))}),
                    },
                    .Slice => {
                        if (ptr.child == u8) {
                            rc = c.sqlite3_bind_text(stmt, bind_index, arg.ptr, @intCast(arg.len), c.SQLITE_STATIC);
                        } else {
                            std.debug.print("Unsupported array type '{any}'", .{@typeInfo(ptr.child)});
                        }
                    },
                    else => std.debug.print("Unsupported type '{any}'", .{@typeInfo(@TypeOf(arg))}),
                }
            },
            else => std.debug.print("Unsupported type '{any}'", .{@typeInfo(@TypeOf(arg))}),
        }
    }
};
