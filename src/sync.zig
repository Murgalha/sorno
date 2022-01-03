const c = @import("c.zig");
const data = @import("data.zig");
const Element = data.Element;
const Profile = data.Profile;
const Target = data.Target;

pub fn rsync_src_dst_string(arg_profile_name: [*c]u8, arg_e: [*c]Element, arg_t: [*c]Target) [*c]u8 {
    var profile_name = arg_profile_name;
    var e = arg_e;
    var t = arg_t;
    var str: [*c]u8 = c.mtbs_join(@as(c_int, 2), e.*.source, " ");
    if (t.*.address != null) {
        c.mtbs_concat(@as(c_int, 9), &str, t.*.user, "@", t.*.address, ":", t.*.path, profile_name, "/", e.*.destination);
    } else {
        c.mtbs_concat(@as(c_int, 6), &str, " ", t.*.path, profile_name, "/", e.*.destination);
    }
    return str;
}

pub fn sync_profile_to_target(arg_profile: [*c]Profile, arg_target: [*c]Target) void {
    var profile = arg_profile;
    var target = arg_target;
    var cmd_base: [*c]u8 = c.mtbs_new(@intToPtr([*c]u8, @ptrToInt("rsync -azhvP ")));
    var dirs: [*c]u8 = undefined;
    var cmd: [*c]u8 = undefined;
    {
        var i: c_int = 0;
        while (@bitCast(c_uint, i) < profile.*.n_elements) : (i += 1) {
            dirs = rsync_src_dst_string(profile.*.name, profile.*.element + @bitCast(usize, @intCast(isize, i)), target);
            cmd = c.mtbs_join(@as(c_int, 2), cmd_base, dirs);
            _ = c.printf("\nRunning %s\n", cmd);
            _ = c.system(cmd);
            c.free(@ptrCast(?*anyopaque, cmd));
            c.free(@ptrCast(?*anyopaque, dirs));
        }
    }
    c.free(@ptrCast(?*anyopaque, cmd_base));
    return;
}
