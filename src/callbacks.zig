const std = @import("std");
const dm = @import("datamodels.zig");
const c = @import("c.zig");
const mem = std.mem;
const ArrayList = std.ArrayList;
const Target = dm.Target;
const Element = dm.Element;
const Profile = dm.Profile;
const fromCString = @import("utils.zig").fromCString;

fn appendToSlice(comptime T: type, allocator: *const mem.Allocator, slice: []T, item: T) []T {
    // TODO: Handle errors better than silently failing and returning
    var new_list = ArrayList(T).init(allocator.*);
    new_list.appendSlice(slice) catch {
        std.debug.print("Could not append Element slice to Array List\n", .{});
        return new_list.toOwnedSlice();
    };
    new_list.append(item) catch {
        std.debug.print("Could not append new Element to Array List\n", .{});
        return new_list.toOwnedSlice();
    };

    return new_list.toOwnedSlice();
}

pub fn selectTargetCallback(ptr: ?*anyopaque, ncols: c_int, columns: [*c][*c]u8, names: [*c][*c]u8) callconv(.C) c_int {
    var list = @ptrCast(*ArrayList(Target), @alignCast(@alignOf(*ArrayList(Target)), ptr.?));
    var target: Target = undefined;

    var i: usize = 0;
    while (i < ncols) : (i += 1) {
        if (std.mem.eql(u8, std.mem.span(names[i]), "id")) {
            target.id = @intCast(u64, c.atoi(columns[i]));
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "name")) {
            target.name = fromCString(&list.allocator, columns[i]);
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "user")) {
            target.user = fromCString(&list.allocator, columns[i]);
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "path")) {
            target.path = fromCString(&list.allocator, columns[i]);
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "address")) {
            target.address = fromCString(&list.allocator, columns[i]);
        }
    }

    list.append(target) catch {
        std.debug.print("Could not append to Array List\n", .{});
        return -1;
    };

    return 0;
}

pub fn selectProfileNameCallback(ptr: ?*anyopaque, ncols: c_int, columns: [*c][*c]u8, names: [*c][*c]u8) callconv(.C) c_int {
    var list = @ptrCast(*ArrayList(Profile), @alignCast(@alignOf(*ArrayList(Profile)), ptr.?));
    var profile: Profile = undefined;

    var i: usize = 0;
    while (i < ncols) : (i += 1) {
        if (std.mem.eql(u8, std.mem.span(names[i]), "id")) {
            profile.id = @intCast(u64, c.atoi(columns[i]));
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "name")) {
            profile.name = fromCString(&list.allocator, columns[i]);
        }
    }
    profile.elements = &.{};

    list.append(profile) catch {
        std.debug.print("Could not append []u8 to Array List\n", .{});
        return -1;
    };

    return 0;
}

pub fn selectElementCallback(ptr: ?*anyopaque, ncols: c_int, columns: [*c][*c]u8, names: [*c][*c]u8) callconv(.C) c_int {
    var list = @ptrCast(*ArrayList(Element), @alignCast(@alignOf(*ArrayList(Element)), ptr.?));
    var element: Element = undefined;

    var i: usize = 0;
    while (i < ncols) : (i += 1) {
        if (std.mem.eql(u8, std.mem.span(names[i]), "id")) {
            element.id = @intCast(u64, c.atoi(columns[i]));
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "name")) {
            element.name = fromCString(&list.allocator, columns[i]);
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "source")) {
            element.source = fromCString(&list.allocator, columns[i]);
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "destination")) {
            element.destination = fromCString(&list.allocator, columns[i]);
        }
    }

    list.append(element) catch {
        std.debug.print("Could not append to Array List\n", .{});
        return -1;
    };

    return 0;
}

pub fn selectProfileCallback(ptr: ?*anyopaque, ncols: c_int, columns: [*c][*c]u8, names: [*c][*c]u8) callconv(.C) c_int {
    var list = @ptrCast(*ArrayList(Profile), @alignCast(@alignOf(*ArrayList(Profile)), ptr.?));
    var profile: Profile = undefined;
    var p_id: u64 = undefined;
    var p_name: []const u8 = undefined;
    var element: Element = undefined;
    var found = false;

    var i: usize = 0;
    while (i < ncols) : (i += 1) {
        if (std.mem.eql(u8, std.mem.span(names[i]), "profile_id")) {
            p_id = @intCast(u64, c.atoi(columns[i]));
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "profile_name")) {
            p_name = fromCString(&list.allocator, columns[i]);
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "element_id")) {
            element.id = @intCast(u64, c.atoi(columns[i]));
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "element_name")) {
            element.name = fromCString(&list.allocator, columns[i]);
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "element_source")) {
            element.source = fromCString(&list.allocator, columns[i]);
        } else if (std.mem.eql(u8, std.mem.span(names[i]), "element_destination")) {
            element.destination = fromCString(&list.allocator, columns[i]);
        }
    }

    var k: usize = 0;
    for (list.items) |prof| {
        if (prof.id == p_id) {
            found = true;
            break;
        }
        k += 1;
    }

    if (found) {
        list.items[k].elements = appendToSlice(Element, &list.allocator, list.items[k].elements, element);
    } else {
        profile.id = p_id;
        profile.name = p_name;
        profile.elements = appendToSlice(Element, &list.allocator, &.{}, element);

        list.append(profile) catch {
            std.debug.print("Could not append Profile to Array List\n", .{});
            return -1;
        };
    }

    return 0;
}
