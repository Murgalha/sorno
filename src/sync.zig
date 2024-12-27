const std = @import("std");
const c = @import("c.zig");
const dm = @import("datamodels.zig");
const utils = @import("utils.zig");
const Element = dm.Element;
const Profile = dm.Profile;
const Target = dm.Target;
const mem = std.mem;
const cstr = std.cstr;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();

pub fn getSyncSrcAndDstString(allocator: *const mem.Allocator, profile_name: []u8, e: Element, t: Target) ![]u8 {
    // TODO: Rsync will not create all the directories needed, only the last one
    // We must create it with an ssh command previously to guarantee
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    try list.append('"');
    try list.appendSlice(e.source);
    try list.append('"');
    try list.append(' ');

    if (t.address.len != 0) {
        try list.append('"');
        try list.appendSlice(t.user);
        try list.append('@');
        try list.appendSlice(t.address);
        try list.append(':');
        try list.appendSlice(t.path);
        try list.appendSlice(profile_name);
        try list.append('/');
        try list.appendSlice(e.destination);
        try list.append('"');
    } else {
        try list.append(' ');
        try list.append('"');
        try list.appendSlice(t.path);
        try list.appendSlice(profile_name);
        try list.append('/');
        try list.appendSlice(e.destination);
        try list.append('"');
    }
    return list.toOwnedSlice();
}

pub fn getRestoreSrcAndDstString(allocator: *const mem.Allocator, profile: Profile, target: Target) ![]u8 {
    // rsync -azhvP {t.user}@{t.address}:{t.path}{t.name} /tmp/sorno/
    const cmd_base = "rsync -sazhvP ";
    const tmp_dir = "/tmp/sorno/";
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    try list.appendSlice(cmd_base);
    try list.append('"');
    try list.appendSlice(target.user);
    try list.append('@');
    try list.appendSlice(target.address);
    try list.append(':');
    try list.appendSlice(target.path);
    try list.appendSlice(profile.name);
    try list.append('"');
    try list.append(' ');
    try list.append('"');
    try list.appendSlice(tmp_dir);
    try list.append('"');

    return list.toOwnedSlice();
}

pub fn syncProfileToTarget(allocator: *const mem.Allocator, profile: Profile, target: Target, password: []u8) !void {
    const cmd_base = "rsync -sazhvP ";

    const sshpass_cmd = try getSshpassCmd(allocator, password);
    for (profile.elements) |element| {
        var list = ArrayList(u8).init(allocator.*);
        defer list.deinit();

        try list.appendSlice(sshpass_cmd);
        try list.appendSlice(cmd_base);

        const dirs = try getSyncSrcAndDstString(allocator, profile.name, element, target);
        try list.appendSlice(dirs);
        const cmd = try list.toOwnedSlice();

        try stdout.print("\nRunning {s} {s}\n", .{ cmd_base, dirs });
        _ = c.system(try allocator.*.dupeZ(u8, cmd));
    }

    return;
}

pub fn getRestoreCopyCmd(allocator: *const mem.Allocator, profile_name: []u8, element: Element) ![]u8 {
    // cp -r /tmp/sorno/{p.name}/{e.destination} {e.source}
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();
    const base = "cp -r ";
    const tmp_dir = "/tmp/sorno/";

    try list.appendSlice(base);

    try list.append('"');
    try list.appendSlice(tmp_dir);
    try list.appendSlice(profile_name);
    try list.append('/');
    try list.appendSlice(element.destination);
    try list.append('"');
    try list.append(' ');
    try list.append('"');

    try list.appendSlice("/tmp/sorno/test/");
    //try list.appendSlice(element.source);
    try list.append('"');

    return try list.toOwnedSlice();
}

pub fn restoreProfileFromTarget(allocator: *const mem.Allocator, profile: Profile, target: Target, password: []u8) !void {
    // TODO: There should be a safe way to create the destination directory and copy stuff there
    // without having same name subdirectory, like '/path/directory/directory/content
    const restore_cmd = try getRestoreSrcAndDstString(allocator, profile, target);
    const sshpass_cmd = try getSshpassCmd(allocator, password);

    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    try list.appendSlice(sshpass_cmd);
    try list.append(' ');
    try list.appendSlice(restore_cmd);
    const full_cmd = try list.toOwnedSlice();

    try stdout.print("\nRunning {s}\n", .{restore_cmd});
    _ = c.system(try allocator.*.dupeZ(u8, full_cmd));

    for (profile.elements) |element| {
        const copy_cmd = try getRestoreCopyCmd(allocator, profile.name, element);
        std.debug.print("\nRunning {s}\n", .{copy_cmd});
        _ = c.system(try allocator.*.dupeZ(u8, copy_cmd));
    }
}

fn getSshpassCmd(allocator: *const mem.Allocator, password: []u8) ![]u8 {
    const sshpass = "sshpass -p ";

    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();
    try list.appendSlice(sshpass);
    try list.append('"');
    try list.appendSlice(password);
    try list.append('"');
    try list.append(' ');

    return try list.toOwnedSlice();
}
