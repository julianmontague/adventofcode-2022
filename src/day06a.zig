//! Advent of Code 2022 Day 6 part 1 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const MAX_SIZE = 8192;

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_dir = try std.fs.cwd().openDir("input", .{});
    const file = try input_dir.openFile("day06.txt", .{});
    defer file.close();

    var buffer: [MAX_SIZE]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const data = try file.reader().readAllAlloc(fba.allocator(), MAX_SIZE);
    var pos: usize = 3;
    var marker: bool = false;

    while (pos < data.len and !marker) {
        pos += 1;
        marker = true;
        const seq = data[pos - 4 .. pos];
        try out.print("{s} {d}\n", .{ seq, pos });
        for (seq) |char| {
            const char_arr: [1]u8 = [_]u8{char};
            if (std.mem.count(u8, seq, &char_arr) > 1) {
                marker = false;
            }
        }
    }

    try out.print("Answer: {d}\n", .{pos});
}
