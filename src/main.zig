const std = @import("std");
const Database = @import("database.zig").Database;
const sync = @import("sync.zig");
const dm = @import("datamodels.zig");
const Element = dm.Element;
const Profile = dm.Profile;
const Target = dm.Target;
const stdout = std.io.getStdOut().writer();
const Tui = @import("tui.zig").Tui;

pub fn add_profile(tui: Tui, db: Database) !void {
    var prof: Profile = undefined;
    prof = try tui.readProfile();
    try db.insert(prof);
}

pub fn add_element(tui: Tui, db: Database) !void {
    var element: Element = undefined;
    element = try tui.readElement();
    try db.insert(element);
}

pub fn add_target(tui: Tui, db: Database) !void {
    var target: Target = undefined;
    target = try tui.readTarget();
    try db.insert(target);
}

pub fn link_element(tui: Tui, db: Database) !void {
    var p_idx: usize = undefined;
    var e_idx: usize = undefined;

    var elements = try db.selectUnlinkedElements();
    var profiles = try db.selectProfileNames();

    e_idx = tui.selectElement("Select the element to link:\n"[0..], elements) catch {
        try stdout.print("There are no elements to choose\n", .{});
        return;
    };
    p_idx = tui.selectProfile("Select the profile to link to:\n"[0..], profiles) catch {
        try stdout.print("There are no profiles to choose\n", .{});
        return;
    };

    var element = elements[e_idx];
    var profile = profiles[p_idx];

    try db.linkElement(element, profile);
}

pub fn sync_profile(tui: Tui, db: Database) !void {
    var p_idx: usize = undefined;
    var t_idx: usize = undefined;

    var profiles = try db.selectProfileNames();

    p_idx = tui.selectProfile("Choose the profile to sync:\n"[0..], profiles) catch {
        try stdout.print("There are no profiles to choose\n", .{});
        return;
    };

    var profile_name = profiles[p_idx].name;
    var targets = try db.selectTargets();
    t_idx = tui.selectTarget("Choose target to sync:\n"[0..], targets) catch {
        try stdout.print("There are no targets to choose\n", .{});
        return;
    };
    var full_profile = try db.selectProfile(profile_name);
    try sync.syncProfileToTarget(db.allocator, full_profile, targets[t_idx]);
}

pub fn restore_profile(tui: Tui, db: Database) !void {
    var p_idx: usize = undefined;
    var t_idx: usize = undefined;

    var profiles = try db.selectProfileNames();

    p_idx = tui.selectProfile("Choose the profile to restore:\n"[0..], profiles) catch {
        try stdout.print("There are no profiles to choose\n", .{});
        return;
    };

    var profile_name = profiles[p_idx].name;
    var targets = try db.selectTargets();
    t_idx = tui.selectTarget("Choose target to restore from:\n"[0..], targets) catch {
        try stdout.print("There are no targets to choose\n", .{});
        return;
    };
    var full_profile = try db.selectProfile(profile_name);
    try sync.restoreProfileFromTarget(db.allocator, full_profile, targets[t_idx]);
}

pub fn main() !void {
    var quit: bool = false;
    var opt: u64 = undefined;

    const allocator = std.heap.page_allocator;

    var db = try Database.open(&allocator);
    defer db.close();
    var tui = try Tui.init(&allocator);
    defer tui.deinit();

    while (!quit) {
        try stdout.print("\n", .{});
        try stdout.print("1: Add profile\n", .{});
        try stdout.print("2: Add element\n", .{});
        try stdout.print("3: Add target\n", .{});
        try stdout.print("4: Link element\n", .{});
        try stdout.print("5: Sync profile\n", .{});
        try stdout.print("6: Restore profile\n", .{});
        try stdout.print("7: Quit\n", .{});

        opt = tui.readU64("") catch 0;

        while (true) {
            switch (opt) {
                1 => {
                    try add_profile(tui, db);
                    break;
                },
                2 => {
                    try add_element(tui, db);
                    break;
                },
                3 => {
                    try add_target(tui, db);
                    break;
                },
                4 => {
                    try link_element(tui, db);
                    break;
                },
                5 => {
                    try sync_profile(tui, db);
                    break;
                },
                6 => {
                    try restore_profile(tui, db);
                    break;
                },
                7 => {
                    quit = true;
                    break;
                },
                else => {
                    try stdout.print("Invalid command! Enter a valid one\n", .{});
                    break;
                },
            }
            break;
        }
    }
}
