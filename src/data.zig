const c = @import("c.zig");
const free = c.free;
const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;
const stdout = std.io.getStdOut().writer();

pub const Element = struct {
    id: u64,
    name: []u8,
    source: []u8,
    destination: []u8,
};

pub const Profile = struct {
    id: u64,
    name: []u8,
    elements: []Element,
};

pub const Target = struct {
    id: u64,
    name: []u8,
    user: []u8,
    address: []u8,
    path: []u8,
};

pub fn printTarget(target: Target) !void {
    try stdout.print("Type: Target\t Name: '{s}'\n", .{target.name});
    try stdout.print("ID: {d}\n", .{target.id});
    try stdout.print("Address: '{s}'\n", .{target.address});
    try stdout.print("User: '{s}'\n", .{target.user});
    try stdout.print("Path: '{s}'\n", .{target.path});
}

pub fn printElement(element: Element) !void {
    std.debug.print("ID: {d}\n", .{element.id});
    try stdout.print("Name: '{s}'\n", .{element.name});
    try stdout.print("Source: '{s}'\n", .{element.source});
    try stdout.print("Destination: '{s}'\n", .{element.destination});
}

pub fn printProfile(p: Profile) !void {
    try stdout.print("Profile name: {s}\tID: {d}\n", .{ p.name, p.id });
    try stdout.print("{d} Elements:\n", .{p.elements.len});

    for (p.elements) |element| {
        try printElement(element);
    }
}
