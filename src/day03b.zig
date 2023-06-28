//! Advent of Code 2022 Day 3 part 2 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const BUFFER_SIZE = 100;
const LOWERCASE_PRIORITY_CONV: u8 = 96;
const UPPERCASE_PRIORITY_CONV: u8 = 38;

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const inputDir = try std.fs.cwd().openDir("input", .{});
    const file = try inputDir.openFile("day03.txt", .{});
    defer file.close();

    var buffer1: [BUFFER_SIZE]u8 = undefined;
    var buffer2: [BUFFER_SIZE]u8 = undefined;
    var buffer3: [BUFFER_SIZE]u8 = undefined;
    var fba1 = std.heap.FixedBufferAllocator.init(&buffer1);
    var fba2 = std.heap.FixedBufferAllocator.init(&buffer2);
    var fba3 = std.heap.FixedBufferAllocator.init(&buffer3);
    var sack1: ?[]const u8 = try nextLineAlloc(file.reader(), fba1.allocator(), BUFFER_SIZE);
    var sum: u64 = 0;

    while (sack1 != null) {
        const allocator2 = fba2.allocator();
        const allocator3 = fba3.allocator();
        const sack2: ?[]const u8 = try nextLineAlloc(file.reader(), allocator2, BUFFER_SIZE);
        const sack3: ?[]const u8 = try nextLineAlloc(file.reader(), allocator3, BUFFER_SIZE);
        const badge: u8 = try findCommonChar(sack1.?, sack2.?, sack3.?);
        var priority: u8 = undefined;
        if (std.ascii.isLower(badge)) {
            priority = badge - LOWERCASE_PRIORITY_CONV;
        } else {
            priority = badge - UPPERCASE_PRIORITY_CONV;
        }
        sum += priority;
        try out.print("{s}\n{s}\n{s}\nBadge: {c}\n\n", .{ sack1.?, sack2.?, sack3.?, badge });
        fba1.reset();
        fba2.reset();
        fba3.reset();
        sack1 = try nextLineAlloc(file.reader(), fba1.allocator(), BUFFER_SIZE);
    }

    try out.print("Answer: {d} points\n", .{sum});
}

pub fn nextLineAlloc(reader: anytype, allocator: std.mem.Allocator, max_size: usize) !?[]u8 {
    var array_list = std.ArrayList(u8).init(allocator);
    defer array_list.deinit();
    reader.streamUntilDelimiter(array_list.writer(), '\n', max_size) catch |err| switch (err) {
        error.EndOfStream => if (array_list.items.len == 0) {
            return null;
        },

        else => |e| return e,
    };
    return try array_list.toOwnedSlice();
}

pub fn findCommonChar(str1: []const u8, str2: []const u8, str3: []const u8) !u8 {
    var buffer: [BUFFER_SIZE]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var common = std.ArrayList(u8).init(allocator);
    for (str1) |char| {
        const charArr: [1]u8 = [_]u8{char};
        if (std.mem.count(u8, str2, &charArr) > 0) {
            try common.append(char);
        }
    }
    for (common.items) |char| {
        const charArr: [1]u8 = [_]u8{char};
        if (std.mem.count(u8, str3, &charArr) > 0) {
            return char;
        }
    }
    return error.NoCharacterInCommon;
}
