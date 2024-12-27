const std = @import("std");
const mem = std.mem;
const utils = @import("utils.zig");
const Tui = @import("tui.zig").Tui;
const Database = @import("database.zig").Database;
const dm = @import("datamodels.zig");
const sync = @import("sync.zig");
const Element = dm.Element;
const Target = dm.Target;
const Profile = dm.Profile;
const stdout = std.io.getStdOut().writer();
const AutoHashMap = std.hash_map.AutoHashMap;

const Tuple = struct {
    const Self = @This();
    string: []const u8,
    function: *const fn (*MainMenu) anyerror!void,

    pub fn new(str: []const u8, func: *const fn (*MainMenu) anyerror!void) Self {
        return Self{
            .string = str,
            .function = func,
        };
    }
};

pub const MainMenu = struct {
    const Self = @This();
    options: AutoHashMap(u64, Tuple),
    should_quit: bool,
    tui: *Tui,
    db: *Database,
    allocator: *const mem.Allocator,

    pub fn init(allocator: *const mem.Allocator, tui: *Tui, db: *Database) !Self {
        return Self{
            .options = try getMainMenuOptions(allocator),
            .tui = tui,
            .db = db,
            .should_quit = false,
            .allocator = allocator,
        };
    }

    pub fn run(self: *Self) !void {
        var opt: u64 = 0;
        while (!self.should_quit) {
            try self.printMainMenu();

            opt = utils.readU64(self.allocator, "") catch 0;

            _ = try self.options.get(opt).?.function(self);
        }
    }

    fn printMainMenu(self: *Self) !void {
        const n_items = self.options.count();
        try stdout.print("\n", .{});
        var i: u64 = 1;
        while (i <= n_items) : (i += 1) {
            const tuple = self.options.get(i).?;
            try stdout.print("{d}: {s}\n", .{ i, tuple.string });
        }
    }

    fn getMainMenuOptions(allocator: *const mem.Allocator) !AutoHashMap(u64, Tuple) {
        var hash_map = AutoHashMap(u64, Tuple).init(allocator.*);

        try hash_map.put(1, Tuple.new("Add profile"[0..], addProfile));
        try hash_map.put(2, Tuple.new("Add element"[0..], addElement));
        try hash_map.put(3, Tuple.new("Add target"[0..], addTarget));
        try hash_map.put(4, Tuple.new("Link element"[0..], linkElement));
        try hash_map.put(5, Tuple.new("Sync profile"[0..], syncProfile));
        try hash_map.put(6, Tuple.new("Restore profile"[0..], restoreProfile));
        try hash_map.put(7, Tuple.new("Quit"[0..], quit));

        return hash_map;
    }
};

pub fn addProfile(menu: *MainMenu) !void {
    var prof: Profile = undefined;
    prof = menu.tui.readProfile() catch unreachable;
    menu.db.insert(prof) catch unreachable;
}

pub fn addElement(menu: *MainMenu) !void {
    var element: Element = undefined;
    element = try menu.tui.readElement();
    try menu.db.insert(element);
}

pub fn addTarget(menu: *MainMenu) !void {
    var target: Target = undefined;
    target = try menu.tui.readTarget();
    try menu.db.insert(target);
}

pub fn linkElement(menu: *MainMenu) !void {
    var p_idx: usize = undefined;
    var e_idx: usize = undefined;

    const elements = try menu.db.selectUnlinkedElements();
    const profiles = try menu.db.selectProfileNames();

    e_idx = menu.tui.selectElement("Select the element to link:\n"[0..], elements) catch {
        try stdout.print("There are no elements to choose\n", .{});
        return;
    };
    p_idx = menu.tui.selectProfile("Select the profile to link to:\n"[0..], profiles) catch {
        try stdout.print("There are no profiles to choose\n", .{});
        return;
    };

    const element = elements[e_idx];
    const profile = profiles[p_idx];

    try menu.db.linkElement(element, profile);
}

pub fn syncProfile(menu: *MainMenu) !void {
    var p_idx: usize = undefined;
    var t_idx: usize = undefined;

    const profiles = try menu.db.selectProfileNames();

    p_idx = menu.tui.selectProfile("Choose the profile to sync:\n"[0..], profiles) catch {
        try stdout.print("There are no profiles to choose\n", .{});
        return;
    };

    const profile_name = profiles[p_idx].name;
    const targets = try menu.db.selectTargets();
    t_idx = menu.tui.selectTarget("Choose target to sync:\n"[0..], targets) catch {
        try stdout.print("There are no targets to choose\n", .{});
        return;
    };

    const pw = try menu.tui.readTargetPassword("Enter remote user password: ");

    const full_profile = try menu.db.selectProfile(profile_name);
    try sync.syncProfileToTarget(menu.db.allocator, full_profile, targets[t_idx], pw);
}

pub fn restoreProfile(menu: *MainMenu) !void {
    var p_idx: usize = undefined;
    var t_idx: usize = undefined;

    const profiles = try menu.db.selectProfileNames();

    p_idx = menu.tui.selectProfile("Choose the profile to restore:\n"[0..], profiles) catch {
        try stdout.print("There are no profiles to choose\n", .{});
        return;
    };

    const profile_name = profiles[p_idx].name;
    const targets = try menu.db.selectTargets();
    t_idx = menu.tui.selectTarget("Choose target to restore from:\n"[0..], targets) catch {
        try stdout.print("There are no targets to choose\n", .{});
        return;
    };
    const pw = try menu.tui.readTargetPassword("Enter remote user password: ");
    const full_profile = try menu.db.selectProfile(profile_name);
    try sync.restoreProfileFromTarget(menu.db.allocator, full_profile, targets[t_idx], pw);
}

pub fn quit(menu: *MainMenu) !void {
    menu.should_quit = true;
}
