const std = @import("std");
const Database = @import("database.zig").Database;
const sync = @import("sync.zig");
const dm = @import("datamodels.zig");
const Element = dm.Element;
const Profile = dm.Profile;
const Target = dm.Target;
const stdout = std.io.getStdOut().writer();
const Tui = @import("tui.zig").Tui;
const MainMenu = @import("mainmenu.zig").MainMenu;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var db = try Database.open(&allocator);
    defer db.close();
    var tui = try Tui.init(&allocator);
    defer tui.deinit();

    var main_menu = try MainMenu.init(&allocator, &tui, &db);
    try main_menu.run();
}
