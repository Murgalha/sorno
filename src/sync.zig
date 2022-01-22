const std = @import("std");
const c = @import("c.zig");
const dm = @import("datamodels.zig");
const Element = dm.Element;
const Profile = dm.Profile;
const Target = dm.Target;
const mem = std.mem;
const cstr = std.cstr;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();

pub fn getSrcAndDstString(allocator: *const mem.Allocator, profile_name: []u8, e: Element, t: Target) ![]u8 {
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    try list.appendSlice(e.source);
    try list.append(' ');

    if (t.address.len != 0) {
        try list.appendSlice(t.user);
        try list.append('@');
        try list.appendSlice(t.address);
        try list.append(':');
        try list.appendSlice(t.path);
        try list.appendSlice(profile_name);
        try list.append('/');
        try list.appendSlice(e.destination);
    } else {
        try list.append(' ');
        try list.appendSlice(t.path);
        try list.appendSlice(profile_name);
        try list.append('/');
        try list.appendSlice(e.destination);
    }
    return list.toOwnedSlice();
}

pub fn syncProfileToTarget(allocator: *const mem.Allocator, profile: Profile, target: Target) !void {
    var cmd_base = "rsync -azhvP ";

    for (profile.elements) |element| {
        var list = ArrayList(u8).init(allocator.*);
        defer list.deinit();

        try list.appendSlice(cmd_base);

        var dirs = try getSrcAndDstString(allocator, profile.name, element, target);
        try list.appendSlice(dirs);
        var cmd = list.toOwnedSlice();

        try stdout.print("\nRunning {s}\n", .{cmd});
        _ = c.system(try cstr.addNullByte(allocator.*, cmd));
    }

    return;
}
