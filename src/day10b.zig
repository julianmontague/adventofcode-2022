//! Advent of Code 2022 Day 10 part 2 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const WIDTH = 40;
const HEIGHT = 6;

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const input_file = try input_cur_dir.openFile("day10.txt", .{});
    defer input_file.close();

    var buffer: [10]u8 = undefined;
    var wait = false;
    var X: i64 = 1;
    var output: []const u8 = (try nextLine(input_file.reader(), &buffer)).?;
    var screen = [_][WIDTH]u8{.{'.'} ** WIDTH} ** HEIGHT;

    for (1..WIDTH * HEIGHT) |cycle| {
        const x = (cycle - 1) % WIDTH;
        if (try std.math.absInt(X - @as(i64, @intCast(x))) <= 1) {
            screen[cycle / WIDTH][x] = '#';
        }

        if (std.mem.count(u8, output, "addx") > 0) {
            if (wait) {
                X += try std.fmt.parseInt(i8, output[5..output.len], 10);
                output = (try nextLine(input_file.reader(), &buffer)).?;
                wait = false;
            } else {
                wait = true;
            }
        } else if (std.mem.eql(u8, output, "noop")) {
            output = (try nextLine(input_file.reader(), &buffer)).?;
        } else {
            return error.UnknownInstruction;
        }
    }

    try out.writeAll("Answer:\n");

    for (screen) |row| {
        for (row) |pixel| {
            try out.writeByte(pixel);
        }
        try out.writeByte('\n');
    }
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
