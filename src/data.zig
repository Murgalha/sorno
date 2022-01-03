const c = @import("c.zig");
const free = c.free;
const printf = c.printf;

pub const Element = extern struct {
    name: [*c]u8,
    source: [*c]u8,
    destination: [*c]u8,
};

pub const Profile = extern struct {
    name: [*c]u8,
    n_elements: c_uint,
    element: [*c]Element,
};

pub const Target = extern struct {
    name: [*c]u8,
    user: [*c]u8,
    address: [*c]u8,
    path: [*c]u8,
};

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

pub fn target_print(arg_target: [*c]Target) void {
    var target = arg_target;
    _ = printf("Name: %s\n", target.*.name);
    _ = printf("Address: %s\n", target.*.address);
    _ = printf("User: %s\n", target.*.user);
    _ = printf("Path: %s\n", target.*.path);
}

pub fn element_free(arg_e: [*c]Element) void {
    var e = arg_e;
    if (!(e != null)) {
        return;
    }
    free(@ptrCast(?*anyopaque, e.*.name));
    free(@ptrCast(?*anyopaque, e.*.source));
    free(@ptrCast(?*anyopaque, e.*.destination));
    free(@ptrCast(?*anyopaque, e));
}

pub fn element_print(arg_element: [*c]Element) void {
    var element = arg_element;
    _ = printf("Name: %s\n", element.*.name);
    _ = printf("Source: %s\n", element.*.source);
    _ = printf("Destination: %s\n", element.*.destination);
}

pub fn profile_free(arg_p: [*c]Profile) void {
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

pub fn profile_print(arg_p: [*c]Profile) void {
    var p = arg_p;
    _ = printf("Profile name: %s\n", p.*.name);
    _ = printf("Elements:\n");
    {
        var i: c_int = 0;
        while (@bitCast(c_uint, i) < p.*.n_elements) : (i += 1) {
            element_print(p.*.element + @bitCast(usize, @intCast(isize, i)));
        }
    }
}
