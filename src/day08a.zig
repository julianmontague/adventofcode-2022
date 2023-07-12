//! Advent of Code 2022 Day 8 part 1 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const WIDTH = 99;

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const file = try input_cur_dir.openFile("day08.txt", .{});
    defer file.close();

    var buffer: [WIDTH + 1]u8 = undefined;
    var line: usize = 0;
    var trees: [WIDTH][WIDTH]u8 = undefined;
    var visible_trees = [_][WIDTH]bool{.{false} ** WIDTH} ** WIDTH;

    while (try nextLine(file.reader(), &buffer)) |output| : (line += 1) {
        if (output.len != WIDTH) {
            return error.WidthMismatch;
        }
        for (output, 0..) |char, i| {
            const char_arr: [1]u8 = [_]u8{char};
            trees[line][i] = try std.fmt.parseUnsigned(u8, &char_arr, 10);
        }
    }

    if (line != WIDTH) {
        return error.WidthMismatch;
    }

    // set first and last rows to visible
    visible_trees[0] = .{true} ** WIDTH;
    visible_trees[WIDTH - 1] = .{true} ** WIDTH;

    // checking visibility along rows from left
    for (trees, 0..) |row, y| {
        var max_height: u8 = 0;
        for (row, 0..) |height, x| {
            setTreeVisibility(x, y, height, &max_height, &visible_trees);
        }
    }

    // checking visibility along rows from right
    for (trees, 0..) |row, y| {
        var max_height: u8 = 0;
        for (0..WIDTH - 1) |i| {
            const x = WIDTH - 1 - i;
            const height = row[x];
            setTreeVisibility(x, y, height, &max_height, &visible_trees);
        }
    }

    // checking visibility along columns from top
    for (0..WIDTH - 1) |x| {
        var max_height: u8 = 0;
        for (trees, 0..) |row, y| {
            const height = row[x];
            setTreeVisibility(x, y, height, &max_height, &visible_trees);
        }
    }

    // checking visibility along columns from bottom
    for (0..WIDTH - 1) |x| {
        var max_height: u8 = 0;
        for (0..WIDTH - 1) |i| {
            const y = WIDTH - 1 - i;
            const height = trees[y][x];
            setTreeVisibility(x, y, height, &max_height, &visible_trees);
        }
    }

    var visible_count: u64 = 0;
    for (visible_trees) |row| {
        for (row) |visible| {
            if (visible) {
                visible_count += 1;
            }
        }
    }

    try out.print("Answer: {d}\n", .{visible_count});
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

pub fn setTreeVisibility(x: usize, y: usize, height: u8, max_height: *u8, visibility_array: *[WIDTH][WIDTH]bool) void {
    if (x == 0 or x == WIDTH - 1 or height > max_height.*) {
        max_height.* = height;
        visibility_array[y][x] = true;
    }
}
