const c = @import("c.zig");
const malloc = c.malloc;
const realloc = c.realloc;
const free = c.free;
const FILE = c.FILE;
const fgetc = c.fgetc;
const printf = c.printf;
const data = @import("data.zig");
const Element = data.Element;
const Profile = data.Profile;
const Target = data.Target;

pub fn clear_stdin() void {
    var ch: u8 = undefined;
    while (true) {
        ch = @bitCast(u8, @truncate(i8, fgetc(c.stdin)));
        if (!((@bitCast(c_int, @as(c_uint, ch)) != @as(c_int, '\n')) and (@bitCast(c_int, @as(c_uint, ch)) != -@as(c_int, 1)))) break;
    }
}

pub fn file_read_line(arg_fp: [*c]FILE) [*c]u8 {
    var fp = arg_fp;
    var len: c_int = 0;
    var capacity: c_int = 2;
    var str: [*c]u8 = @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), malloc(@sizeOf(u8) *% @bitCast(c_ulong, @as(c_long, capacity)))));
    var ch: u8 = undefined;
    while (true) {
        if (len == capacity) {
            capacity <<= @intCast(@import("std").math.Log2Int(c_int), @as(c_int, 2));
            str = @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), realloc(@ptrCast(?*anyopaque, str), @sizeOf(u8) *% @bitCast(c_ulong, @as(c_long, capacity)))));
        }
        ch = @bitCast(u8, @truncate(i8, fgetc(fp)));
        (blk: {
            const tmp = blk_1: {
                const ref = &len;
                const tmp_2 = ref.*;
                ref.* += 1;
                break :blk_1 tmp_2;
            };
            if (tmp >= 0) break :blk str + @intCast(usize, tmp) else break :blk str - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
        }).* = ch;
        if (!(@bitCast(c_int, @as(c_uint, ch)) != @as(c_int, '\n'))) break;
    }
    len -= 1;
    (blk: {
        const tmp = len;
        if (tmp >= 0) break :blk str + @intCast(usize, tmp) else break :blk str - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
    }).* = '\x00';
    if (len == @as(c_int, 0)) {
        free(@ptrCast(?*anyopaque, str));
        return null;
    }
    str = @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), realloc(@ptrCast(?*anyopaque, str), @sizeOf(u8) *% @bitCast(c_ulong, @as(c_long, len + @as(c_int, 1))))));
    return str;
}

pub fn ui_read_target() [*c]Target {
    var target: [*c]Target = @ptrCast([*c]Target, @alignCast(@import("std").meta.alignment(Target), malloc(@sizeOf(Target))));
    target.*.name = ui_read_non_null(@intToPtr([*c]u8, @ptrToInt("Enter the name of the target: ")));
    _ = printf("Enter the address of the target: ");
    target.*.address = file_read_line(c.stdin);
    _ = printf("Enter the user to connect on the target: ");
    target.*.user = file_read_line(c.stdin);
    target.*.path = ui_read_non_null(@intToPtr([*c]u8, @ptrToInt("Enter the path of the target: ")));
    maybe_append_forward_slash(&target.*.path);
    return target;
}

pub fn ui_read_element() [*c]Element {
    var e: [*c]Element = @ptrCast([*c]Element, @alignCast(@import("std").meta.alignment(Element), malloc(@sizeOf(Element))));
    e.*.name = ui_read_non_null(@intToPtr([*c]u8, @ptrToInt("Enter the name of the element: ")));
    e.*.source = ui_read_non_null(@intToPtr([*c]u8, @ptrToInt("Enter the source path of the element: ")));
    maybe_append_forward_slash(&e.*.source);
    _ = printf("Enter the destination path of the element\n(If empty, will be considered basename(source)): ");
    e.*.destination = file_read_line(c.stdin);
    if (!(e.*.destination != null)) {
        e.*.destination = basename(e.*.source);
    }
    maybe_append_forward_slash(&e.*.destination);
    return e;
}

pub fn ui_read_profile() [*c]Profile {
    var p: [*c]Profile = @ptrCast([*c]Profile, @alignCast(@import("std").meta.alignment(Profile), malloc(@sizeOf(Profile))));
    p.*.n_elements = 0;
    p.*.element = null;
    p.*.name = ui_read_non_null(@intToPtr([*c]u8, @ptrToInt("Enter the name of the profile: ")));
    return p;
}

pub fn ui_select_profile(arg_prompt: [*c]u8, arg_profile: [*c]Profile, arg_n: c_int) c_int {
    var prompt = arg_prompt;
    var profile = arg_profile;
    var n = arg_n;
    var opt: u8 = undefined;
    var valid: bool = @as(c_int, 0) != 0;
    if (n == @as(c_int, 0)) {
        _ = printf("There are no profiles to choose\n");
        return -@as(c_int, 1);
    }
    while (!valid) {
        _ = printf("%s", prompt);
        {
            var i: c_int = 0;
            while (i < n) : (i += 1) {
                _ = printf("%d: %s\n", i + @as(c_int, 1), (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk profile + @intCast(usize, tmp) else break :blk profile - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*.name);
            }
        }
        opt = @bitCast(u8, @truncate(i8, c.fgetc(c.stdin)));
        opt = @bitCast(u8, @truncate(i8, c.atoi(&opt)));
        clear_stdin();
        if ((@bitCast(c_int, @as(c_uint, opt)) > @as(c_int, 0)) and (@bitCast(c_int, @as(c_uint, opt)) <= n)) {
            valid = @as(c_int, 1) != 0;
        } else {
            _ = printf("Invalid element\n");
        }
    }
    return @bitCast(c_int, @as(c_uint, opt)) - @as(c_int, 1);
}

pub fn ui_select_element(arg_prompt: [*c]u8, arg_element: [*c]Element, arg_n: c_int) c_int {
    var prompt = arg_prompt;
    var element = arg_element;
    var n = arg_n;
    var opt: u8 = undefined;
    var valid: bool = @as(c_int, 0) != 0;
    if (n == @as(c_int, 0)) {
        _ = printf("There are no elements to choose\n");
        return -@as(c_int, 1);
    }
    while (!valid) {
        _ = printf("%s", prompt);
        {
            var i: c_int = 0;
            while (i < n) : (i += 1) {
                _ = printf("%d: %s\n", i + @as(c_int, 1), (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk element + @intCast(usize, tmp) else break :blk element - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*.name);
            }
        }
        opt = @bitCast(u8, @truncate(i8, c.fgetc(c.stdin)));
        opt = @bitCast(u8, @truncate(i8, c.atoi(&opt)));
        clear_stdin();
        if ((@bitCast(c_int, @as(c_uint, opt)) > @as(c_int, 0)) and (@bitCast(c_int, @as(c_uint, opt)) <= n)) {
            valid = @as(c_int, 1) != 0;
        } else {
            _ = printf("Invalid element\n");
        }
    }
    return @bitCast(c_int, @as(c_uint, opt)) - @as(c_int, 1);
}

pub fn ui_select_target(arg_prompt: [*c]u8, arg_target: [*c]Target, arg_n: c_int) c_int {
    var prompt = arg_prompt;
    var target = arg_target;
    var n = arg_n;
    var opt: u8 = undefined;
    var valid: bool = @as(c_int, 0) != 0;
    if (n == @as(c_int, 0)) {
        _ = printf("There are no targets to choose\n");
        return -@as(c_int, 1);
    }
    while (!valid) {
        _ = printf("%s", prompt);
        {
            var i: c_int = 0;
            while (i < n) : (i += 1) {
                _ = printf("%d: %s\n", i + @as(c_int, 1), (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk target + @intCast(usize, tmp) else break :blk target - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
                }).*.name);
            }
        }
        opt = @bitCast(u8, @truncate(i8, c.fgetc(c.stdin)));
        opt = @bitCast(u8, @truncate(i8, c.atoi(&opt)));
        clear_stdin();
        if ((@bitCast(c_int, @as(c_uint, opt)) > @as(c_int, 0)) and (@bitCast(c_int, @as(c_uint, opt)) <= n)) {
            valid = @as(c_int, 1) != 0;
        } else {
            _ = printf("Invalid target\n");
        }
    }
    return @bitCast(c_int, @as(c_uint, opt)) - @as(c_int, 1);
}

pub fn basename(arg_path: [*c]u8) [*c]u8 {
    var path = arg_path;
    var n: c_int = undefined;
    var tokens: [*c][*c]u8 = c.mtbs_split(path, &n, @intToPtr([*c]u8, @ptrToInt("/")));
    var base: [*c]u8 = c.mtbs_new((blk: {
        const tmp = n - @as(c_int, 1);
        if (tmp >= 0) break :blk tokens + @intCast(usize, tmp) else break :blk tokens - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
    }).*);
    c.mtbs_free_split(tokens, n);
    return base;
}

pub fn maybe_append_forward_slash(arg_path: [*c][*c]u8) void {
    var path = arg_path;
    var len: c_int = @bitCast(c_int, @truncate(c_uint, c.strlen(path.*)));
    if (@bitCast(c_int, @as(c_uint, (blk: {
        const tmp = len - @as(c_int, 1);
        if (tmp >= 0) break :blk path.* + @intCast(usize, tmp) else break :blk path.* - ~@bitCast(usize, @intCast(isize, tmp) +% -1);
    }).*)) == @as(c_int, '/')) return;
    c.mtbs_concat(@as(c_int, 2), path, "/");
}

pub fn ui_read_non_null(arg_input: [*c]u8) [*c]u8 {
    var input = arg_input;
    var valid: bool = @as(c_int, 0) != 0;
    var str: [*c]u8 = undefined;
    while (!valid) {
        _ = printf("%s", input);
        str = file_read_line(c.stdin);
        if (str != null) {
            valid = @as(c_int, 1) != 0;
        } else {
            _ = printf("Error! Must not be empty.\n");
        }
    }
    return str;
}
