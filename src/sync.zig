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

pub fn getSyncSrcAndDstString(allocator: *const mem.Allocator, profile_name: []const u8, e: Element, t: Target) ![]u8 {
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
    var cmd_base = "rsync -sazhvP ";
    var tmp_dir = "/tmp/sorno/";
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

pub fn syncProfileToTarget(allocator: *const mem.Allocator, profile: Profile, target: Target, password: []const u8) !void {
    var cmd_base = "rsync -sazhvP ";

    var sshpass_cmd = try getSshpassCmd(allocator, password);
    for (profile.elements) |element| {
        var list = ArrayList(u8).init(allocator.*);
        defer list.deinit();

        try list.appendSlice(sshpass_cmd);
        try list.appendSlice(cmd_base);

        var dirs = try getSyncSrcAndDstString(allocator, profile.name, element, target);
        try list.appendSlice(dirs);
        var cmd = list.toOwnedSlice();

        try stdout.print("\nRunning {s} {s}\n", .{ cmd_base, dirs });
        _ = c.system(try cstr.addNullByte(allocator.*, cmd));
    }

    return;
}

pub fn getRestoreCopyCmd(allocator: *const mem.Allocator, profile_name: []const u8, element: Element) ![]const u8 {
    // cp -r /tmp/sorno/{p.name}/{e.destination} {e.source}
    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();
    var base = "cp -r ";
    var tmp_dir = "/tmp/sorno/";

    try list.appendSlice(base);

    try list.append('"');
    try list.appendSlice(tmp_dir);
    try list.appendSlice(profile_name);
    try list.append('/');
    try list.appendSlice(element.destination);
    try list.append('"');
    try list.append(' ');
    try list.append('"');

    try list.appendSlice(element.source);
    try list.append('"');

    return list.toOwnedSlice();
}

pub fn restoreProfileFromTarget(allocator: *const mem.Allocator, profile: Profile, target: Target, password: []const u8) !void {
    // TODO: There should be a safe way to create the destination directory and copy stuff there
    // without having same name subdirectory, like '/path/directory/directory/content
    var restore_cmd = try getRestoreSrcAndDstString(allocator, profile, target);
    var sshpass_cmd = try getSshpassCmd(allocator, password);

    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();

    try list.appendSlice(sshpass_cmd);
    try list.append(' ');
    try list.appendSlice(restore_cmd);
    var full_cmd = list.toOwnedSlice();

    try stdout.print("\nRunning {s}\n", .{restore_cmd});
    _ = c.system(try cstr.addNullByte(allocator.*, full_cmd));

    for (profile.elements) |element| {
        var copy_cmd = try getRestoreCopyCmd(allocator, profile.name, element);
        std.debug.print("\nRunning {s}\n", .{copy_cmd});
        _ = c.system(try cstr.addNullByte(allocator.*, copy_cmd));
    }
}

fn getSshpassCmd(allocator: *const mem.Allocator, password: []const u8) ![]const u8 {
    var sshpass = "sshpass -p ";

    var list = ArrayList(u8).init(allocator.*);
    defer list.deinit();
    try list.appendSlice(sshpass);
    try list.append('"');
    try list.appendSlice(password);
    try list.append('"');
    try list.append(' ');

    return list.toOwnedSlice();
}

// ----- TESTS -----
test "getSyncSrcAndDstString" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var profile = "test-profile"[0..];
    var target = Target{
        .id = 1,
        .name = "target-name"[0..],
        .user = "user"[0..],
        .address = "0.0.0.0"[0..],
        .path = "/test/"[0..],
    };
    var element = Element{
        .id = 1,
        .name = "element-name"[0..],
        .source = "/dir/"[0..],
        .destination = "folder/"[0..],
    };
    var expected = "\"/dir/\" \"user@0.0.0.0:/test/test-profile/folder/\"";

    var string = try getSyncSrcAndDstString(&allocator, profile, element, target);
    defer allocator.free(string);

    std.debug.assert(std.mem.eql(u8, expected, string));
}

test "getSyncSrcAndDstString-withEmptyAddress" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var profile = "test-profile"[0..];
    var target = Target{
        .id = 1,
        .name = "target-name"[0..],
        .user = "user"[0..],
        .address = ""[0..],
        .path = "/test/"[0..],
    };
    var element = Element{
        .id = 1,
        .name = "element-name"[0..],
        .source = "/dir/"[0..],
        .destination = "folder/"[0..],
    };
    var expected = "\"/dir/\" \"/test/test-profile/folder/\"";

    var string = try getSyncSrcAndDstString(&allocator, profile, element, target);
    defer allocator.free(string);

    std.debug.assert(std.mem.eql(u8, expected, string));
}

test "getSshpassCmd" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var password = "password";
    var expected = "sshpass -p \"password\" ";

    var string = try getSshpassCmd(&allocator, password);
    defer allocator.free(string);

    std.debug.assert(std.mem.eql(u8, string, expected));
}

test "getRestoreCopyCmd" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var profile = "test-profile"[0..];
    var element = Element{
        .id = 1,
        .name = "element-name"[0..],
        .source = "/dir/"[0..],
        .destination = "folder/"[0..],
    };
    // cp -r /tmp/sorno/{p.name}/{e.destination} {e.source}
    var expected = "cp -r \"/tmp/sorno/test-profile/folder/\" \"/dir/\"";

    var string = try getRestoreCopyCmd(&allocator, profile, element);
    defer allocator.free(string);

    std.debug.print("{s}\n", .{string});
    std.debug.print("{s}\n", .{expected});

    std.debug.assert(std.mem.eql(u8, expected, string));
}
