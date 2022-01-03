const c = @import("c.zig");
const sqlite3 = c.sqlite3;
const database = @import("db.zig");
const ui = @import("ui.zig");
const sync = @import("sync.zig");
const data = @import("data.zig");
const Element = data.Element;
const Profile = data.Profile;
const Target = data.Target;

pub fn add_profile(arg_db: ?*sqlite3) void {
    var db = arg_db;
    var prof: [*c]Profile = undefined;
    prof = ui.ui_read_profile();
    database.db_insert_profile(db, prof);
    data.profile_free(prof);
}

pub fn add_element(arg_db: ?*sqlite3) void {
    var db = arg_db;
    var element: [*c]Element = undefined;
    element = ui.ui_read_element();
    database.db_insert_element(db, element);
    data.element_free(element);
}

pub fn add_target(arg_db: ?*sqlite3) void {
    var db = arg_db;
    var target: [*c]Target = undefined;
    target = ui.ui_read_target();
    database.db_insert_target(db, target);
    data.target_free(target);
}

pub fn link_element(arg_db: ?*sqlite3) void {
    var db = arg_db;
    var profile: [*c]Profile = undefined;
    var element: [*c]Element = undefined;
    var n_profiles: c_int = undefined;
    var p_idx: c_int = undefined;
    var n_elements: c_int = undefined;
    var e_idx: c_int = undefined;
    element = database.db_select_unlinked_elements(db, &n_elements);
    profile = database.db_select_profile_names(db, &n_profiles);
    e_idx = ui.ui_select_element(@intToPtr([*c]u8, @ptrToInt("Select the element to link:\n")), element, n_elements);
    if (e_idx == -@as(c_int, 1)) return;
    p_idx = ui.ui_select_profile(@intToPtr([*c]u8, @ptrToInt("Select the profile to link to:\n")), profile, n_profiles);
    if (p_idx == -@as(c_int, 1)) return;
    database.db_link_element(db, element + @bitCast(usize, @intCast(isize, e_idx)), profile + @bitCast(usize, @intCast(isize, p_idx)));
}

pub fn sync_profile(arg_db: ?*sqlite3) void {
    var db = arg_db;
    var profile: [*c]Profile = undefined;
    var full_profile: [*c]Profile = undefined;
    var target: [*c]Target = undefined;
    var n_profiles: c_int = undefined;
    var p_idx: c_int = undefined;
    var n_targets: c_int = undefined;
    var t_idx: c_int = undefined;
    profile = database.db_select_profile_names(db, &n_profiles);
    p_idx = ui.ui_select_profile(@intToPtr([*c]u8, @ptrToInt("Choose the profile to sync:\n")), profile, n_profiles);
    if (p_idx == -@as(c_int, 1)) return;
    full_profile = database.db_select_profile(db, (profile + @bitCast(usize, @intCast(isize, p_idx))).*.name);
    data.profile_free(profile);
    target = database.db_select_targets(db, &n_targets);
    t_idx = ui.ui_select_target(@intToPtr([*c]u8, @ptrToInt("Choose target to sync:\n")), target, n_targets);
    sync.sync_profile_to_target(full_profile, target + @bitCast(usize, @intCast(isize, t_idx)));
}

pub fn main() void {
    var quit: bool = @as(c_int, 0) != 0;
    var opt: u8 = undefined;
    var db: ?*sqlite3 = database.db_open();
    database.db_create_tables(db);
    while (!quit) {
        _ = c.printf("\n");
        _ = c.printf("1: Add profile\n");
        _ = c.printf("2: Add element\n");
        _ = c.printf("3: Add target\n");
        _ = c.printf("4: Link element\n");
        _ = c.printf("5: Sync profile\n");
        _ = c.printf("6: Quit\n");
        opt = @bitCast(u8, @truncate(i8, c.fgetc(c.stdin)));
        ui.clear_stdin();
        while (true) {
            switch (@bitCast(c_int, @as(c_uint, opt))) {
                @as(c_int, 49) => {
                    add_profile(db);
                    break;
                },
                @as(c_int, 50) => {
                    add_element(db);
                    break;
                },
                @as(c_int, 51) => {
                    add_target(db);
                    break;
                },
                @as(c_int, 52) => {
                    link_element(db);
                    break;
                },
                @as(c_int, 53) => {
                    sync_profile(db);
                    break;
                },
                @as(c_int, 54) => {
                    quit = @as(c_int, 1) != 0;
                    break;
                },
                else => {
                    _ = c.printf("Invalid command! Enter a valid one\n");
                    break;
                },
            }
            break;
        }
    }
    database.db_close(db);
}
