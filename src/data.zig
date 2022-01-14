const c = @import("c.zig");
const free = c.free;
const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();

pub const Element = struct {
    name: []u8,
    source: []u8,
    destination: []u8,
};

pub const Profile = struct {
    name: []u8,
    elements: []Element,
};

pub const Target = struct {
    name: []u8,
    user: []u8,
    address: []u8,
    path: []u8,
};

pub const cElement = extern struct {
    name: [*c]u8,
    source: [*c]u8,
    destination: [*c]u8,
};

pub const cProfile = extern struct {
    name: [*c]u8,
    element: [*c]cElement,
    n_elements: c_int,
};

pub const cTarget = extern struct {
    name: [*c]u8,
    user: [*c]u8,
    address: [*c]u8,
    path: [*c]u8,
};

pub fn toCTarget(target: Target) [*c]cTarget {
    var targ: [*c]cTarget = @ptrCast([*c]cTarget, @alignCast(@import("std").meta.alignment(cTarget), c.malloc(@sizeOf(cTarget))));

    targ.*.name = c.mtbs_new(@ptrCast([*c]u8, target.name));
    targ.*.user = c.mtbs_new(@ptrCast([*c]u8, target.user));
    targ.*.address = c.mtbs_new(@ptrCast([*c]u8, target.address));
    targ.*.path = c.mtbs_new(@ptrCast([*c]u8, target.path));

    return targ;
}

pub fn toCProfile(profile: Profile) [*c]cProfile {
    var prof: [*c]cProfile = @ptrCast([*c]cProfile, @alignCast(@import("std").meta.alignment(cProfile), c.malloc(@sizeOf(cProfile))));

    prof.*.name = c.mtbs_new(@ptrCast([*c]u8, profile.name));

    var elems: [*c]cElement = @ptrCast([*c]cElement, @alignCast(@import("std").meta.alignment(cElement), c.malloc(@sizeOf(cElement) * profile.elements.len)));
    var i: usize = 0;
    while (i < profile.elements.len) : (i += 1) {
        elems[i] = toCElement(profile.elements[i]).*;
    }
    prof.*.element = elems;
    prof.*.n_elements = @intCast(c_int, profile.elements.len);

    return prof;
}

pub fn toCElement(element: Element) [*c]cElement {
    var elem: [*c]cElement = @ptrCast([*c]cElement, @alignCast(@import("std").meta.alignment(cElement), c.malloc(@sizeOf(cElement))));

    elem.*.name = c.mtbs_new(@ptrCast([*c]u8, element.name));
    elem.*.source = c.mtbs_new(@ptrCast([*c]u8, element.source));
    elem.*.destination = c.mtbs_new(@ptrCast([*c]u8, element.destination));

    return elem;
}

pub fn fromCElement(element: cElement) Element {
    var elem: Element = undefined;

    elem.name = std.mem.span(element.name);
    elem.source = std.mem.span(element.source);
    elem.destination = std.mem.span(element.destination);

    return elem;
}

pub fn fromCTarget(target: cTarget) Target {
    var targ: Target = undefined;

    targ.name = std.mem.span(target.name);
    targ.user = std.mem.span(target.user);
    targ.address = std.mem.span(target.address);
    targ.path = std.mem.span(target.path);

    return targ;
}

pub fn fromCProfile(allocator: *const mem.Allocator, profile: cProfile) !Profile {
    var prof: Profile = undefined;

    var list = ArrayList(Element).init(allocator.*);
    defer list.deinit();

    prof.name = std.mem.span(profile.name);

    var i: usize = 0;
    while (i < profile.n_elements) : (i += 1) {
        try list.append(fromCElement(profile.element[i]));
    }
    prof.elements = list.toOwnedSlice();
    return prof;
}

pub fn target_free(arg_t: [*c]Target) void {
    var t = arg_t;
    if (!(t != null)) {
        return;
    }
    free(@ptrCast(?*anyopaque, t.*.name));
    free(@ptrCast(?*anyopaque, t.*.user));
    free(@ptrCast(?*anyopaque, t.*.address));
    free(@ptrCast(?*anyopaque, t.*.path));
    free(@ptrCast(?*anyopaque, t));
}

pub fn target_print(arg_target: [*c]cTarget) !void {
    var target = arg_target;
    try stdout.print("Name: {s}\n", .{target.*.name});
    try stdout.print("Address: {s}\n", .{target.*.address});
    try stdout.print("User: {s}\n", .{target.*.user});
    try stdout.print("Path: {s}\n", .{target.*.path});
}

pub fn element_free(arg_e: [*c]cElement) void {
    var e = arg_e;
    if (!(e != null)) {
        return;
    }
    free(@ptrCast(?*anyopaque, e.*.name));
    free(@ptrCast(?*anyopaque, e.*.source));
    free(@ptrCast(?*anyopaque, e.*.destination));
    free(@ptrCast(?*anyopaque, e));
}

pub fn element_print(arg_element: [*c]cElement) !void {
    var element = arg_element;
    try stdout.print("Name: {s}\n", .{element.*.name});
    try stdout.print("Source: {s}\n", .{element.*.source});
    try stdout.print("Destination: {s}\n", .{element.*.destination});
}

pub fn profile_free(arg_p: [*c]cProfile) void {
    var p = arg_p;
    if (!(p != null)) {
        return;
    }
    free(@ptrCast(?*anyopaque, p.*.name));
    {
        var i: c_int = 0;
        while (@bitCast(c_uint, i) < p.*.n_elements) : (i += 1) {
            element_free(p.*.element + @bitCast(usize, @intCast(isize, i)));
        }
    }
    free(@ptrCast(?*anyopaque, p));
}

pub fn profile_print(arg_p: [*c]cProfile) !void {
    var p = arg_p;
    try stdout.print("Profile name: {s}\n", .{p.*.name});
    try stdout.print("Elements:\n", .{});
    {
        var i: c_int = 0;
        while (@bitCast(c_uint, i) < p.*.n_elements) : (i += 1) {
            try element_print(p.*.element + @bitCast(usize, @intCast(isize, i)));
        }
    }
}
