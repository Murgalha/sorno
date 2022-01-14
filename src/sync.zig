const c = @import("c.zig");
const std = @import("std");
const stdout = std.io.getStdOut().writer();
const data = @import("data.zig");
const Element = data.Element;
const Profile = data.Profile;
const Target = data.Target;

pub fn rsync_src_dst_string(profile_name: [*c]u8, e: Element, t: Target) [*c]u8 {
    var str: [*c]u8 = c.mtbs_join(@as(c_int, 2), @ptrCast([*c]u8, e.source.ptr), " ");

    if (t.address.len != 0) {
        c.mtbs_concat(@as(c_int, 9), &str, @ptrCast([*c]u8, t.user.ptr), "@", @ptrCast([*c]u8, t.address.ptr), ":", @ptrCast([*c]u8, t.path.ptr), @ptrCast([*c]u8, profile_name), "/", @ptrCast([*c]u8, e.destination.ptr));
    } else {
        c.mtbs_concat(@as(c_int, 6), &str, " ", @ptrCast([*c]u8, t.path.ptr), @ptrCast([*c]u8, profile_name), "/", @ptrCast([*c]u8, e.destination.ptr));
    }
    return str;
}

pub fn sync_profile_to_target(profile: Profile, target: Target) !void {
    var cmd_base: [*c]u8 = c.mtbs_new(@intToPtr([*c]u8, @ptrToInt("rsync -azhvP --delete ")));
    var dirs: [*c]u8 = undefined;
    var cmd: [*c]u8 = undefined;

    var i: usize = 0;
    while (i < profile.elements.len) : (i += 1) {
        dirs = rsync_src_dst_string(@ptrCast([*c]u8, profile.name), profile.elements[i], target);
        cmd = c.mtbs_join(@as(c_int, 2), cmd_base, dirs);
        try stdout.print("\nRunning {s}\n", .{cmd});
        _ = c.system(cmd);
        c.free(@ptrCast(?*anyopaque, cmd));
        c.free(@ptrCast(?*anyopaque, dirs));
    }
    c.free(@ptrCast(?*anyopaque, cmd_base));
    return;
}
