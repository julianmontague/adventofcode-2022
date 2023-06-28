//! Advent of Code 2022 Day 1 part 1 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const inputDir = try std.fs.cwd().openDir("input", .{});
    const file = try inputDir.openFile("day01.txt", .{});
    defer file.close();

    var buffer: [10]u8 = undefined;
    var output: []const u8 = undefined;
    var elf: u32 = 0;
    var max: u32 = 0;

    while (!std.mem.eql(u8, output, "stop")) {
        output = (try nextLine(file.reader(), &buffer)) orelse "stop";
        const calories = std.fmt.parseUnsigned(u32, output, 10) catch 0;
        elf += calories;

        if (output.len == 0 or std.mem.eql(u8, output, "stop")) {
            if (elf > max) {
                max = elf;
                try out.print("New max: {d}\n", .{max});
            }
            elf = 0;
        }
    }

    try out.print("Answer: {d}\n", .{max});
}

pub fn nextLine(reader: anytype, buffer: []u8) !?[]u8 {
    var fbs = std.io.fixedBufferStream(buffer);
    reader.streamUntilDelimiter(fbs.writer(), '\n', fbs.buffer.len) catch |err| switch (err) {
        error.EndOfStream => if (fbs.getWritten().len == 0) {
            return null;
        },

        else => |e| return e,
    };
    return fbs.getWritten();
}
