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
    if (t.address.len != 0) {
        return try std.fmt.allocPrint(allocator.*, "\"{s}\" \"{s}@{s}:{s}{s}/{s}\"", .{
            e.source,
            t.user,
            t.address,
            t.path,
            profile_name,
            e.destination,
        });
    } else {
        return try std.fmt.allocPrint(allocator.*, "\"{s}\" \"{s}{s}/{s}\"", .{
            e.source,
            t.path,
            profile_name,
            e.destination,
        });
    }
}

pub fn getRestoreSrcAndDstString(allocator: *const mem.Allocator, profile: Profile, target: Target) ![]u8 {
    // rsync -azhvP {t.user}@{t.address}:{t.path}{t.name} /tmp/sorno/
    const cmd_base = "rsync -sazhvP";
    const tmp_dir = "/tmp/sorno/";

    if (target.address.len != 0) {
        return try std.fmt.allocPrint(allocator.*, "{s} \"{s}@{s}:{s}{s}\" \"{s}\"", .{
            cmd_base,
            target.user,
            target.address,
            target.path,
            profile.name,
            tmp_dir,
        });
    } else {
        return try std.fmt.allocPrint(allocator.*, "{s} \"{s}{s}\" \"{s}\"", .{
            cmd_base,
            target.path,
            profile.name,
            tmp_dir,
        });
    }
}

pub fn syncProfileToTarget(allocator: *const mem.Allocator, profile: Profile, target: Target, password: []u8) !void {
    const cmd_base = "rsync -sazhvP";

    // TODO: Create profile dir before sync'ing
    const sshpass_cmd = try getSshpassCmd(allocator, password);
    defer allocator.free(sshpass_cmd);

    for (profile.elements) |element| {
        const dirs = try getSyncSrcAndDstString(allocator, profile.name, element, target);
        defer allocator.free(dirs);

        const cmd = try std.fmt.allocPrint(allocator.*, "{s} {s} {s}", .{ sshpass_cmd, cmd_base, dirs });
        defer allocator.free(cmd);

        try stdout.print("\nRunning {s} {s}\n", .{ cmd_base, dirs });
        _ = c.system(try allocator.*.dupeZ(u8, cmd));
    }

    return;
}

pub fn getRestoreCopyCmd(allocator: *const mem.Allocator, profile_name: []u8, element: Element) ![]u8 {
    // cp -r /tmp/sorno/{p.name}/{e.destination} {e.source}
    const base = "cp -r";
    const tmp_dir = "/tmp/sorno/";

    return std.fmt.allocPrint(allocator.*, "{s} \"{s}{s}/{s}\"/* \"{s}\"", .{
        base,
        tmp_dir,
        profile_name,
        element.destination,
        element.source,
    });
}

pub fn restoreProfileFromTarget(allocator: *const mem.Allocator, profile: Profile, target: Target, password: []u8) !void {
    // TODO: There should be a safe way to create the destination directory and copy stuff there
    // without having same name subdirectory, like '/path/directory/directory/content

    // TODO: We need to guarantee that the /tmp/sorno folder exists
    const rsync_cmd = try getRestoreSrcAndDstString(allocator, profile, target);
    const restore_cmd = try std.fmt.allocPrint(allocator.*, "{s} {s}", .{
        try getSshpassCmd(allocator, password),
        rsync_cmd,
    });
    defer allocator.free(restore_cmd);
    defer allocator.free(rsync_cmd);

    try stdout.print("\nRunning {s}\n", .{rsync_cmd});
    _ = c.system(try allocator.*.dupeZ(u8, restore_cmd));

    for (profile.elements) |element| {
        const copy_cmd = try getRestoreCopyCmd(allocator, profile.name, element);
        defer allocator.free(copy_cmd);

        std.debug.print("\nRunning {s}\n", .{copy_cmd});
        _ = c.system(try allocator.*.dupeZ(u8, copy_cmd));
    }
}

fn getSshpassCmd(allocator: *const mem.Allocator, password: []u8) ![]u8 {
    const sshpass = "sshpass -p";
    return try std.fmt.allocPrint(allocator.*, "{s} \"{s}\"", .{ sshpass, password });
}
