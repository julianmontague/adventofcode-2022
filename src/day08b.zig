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
    var best_score: u64 = 0;

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

    for (trees, 0..) |row, y| {
        for (row, 0..) |_, x| {
            const score = try getScenicScore(x, y, trees);
            if (score > best_score) {
                best_score = score;
            }
        }
    }

    try out.print("Answer: {d}\n", .{best_score});
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

pub fn getScenicScore(x: usize, y: usize, trees: [WIDTH][WIDTH]u8) !u64 {
    if (x == 0 or x == WIDTH - 1 or y == 0 or y == WIDTH - 1) {
        // one of the sides is going to be zero, and zero * N = zero
        return 0;
    }
    const height = trees[y][x];
    var top: u64 = 0;
    var bottom: u64 = 0;
    var left: u64 = 0;
    var right: u64 = 0;

    const out = std.io.getStdOut().writer();
    try out.print("({d},{d}) height: {d}\n", .{ x, y, height });

    // top
    var cur_y = y - 1;
    while (trees[cur_y][x] < height and cur_y > 0) : (cur_y -= 1) {}
    top = y - cur_y;

    // bottom
    cur_y = y + 1;
    while (trees[cur_y][x] < height and cur_y < WIDTH - 1) : (cur_y += 1) {}
    bottom = cur_y - y;

    // left
    var cur_x = x - 1;
    while (trees[y][cur_x] < height and cur_x > 0) : (cur_x -= 1) {}
    left = x - cur_x;

    // right
    cur_x = x + 1;
    while (trees[y][cur_x] < height and cur_x < WIDTH - 1) : (cur_x += 1) {}
    right = cur_x - x;

    try out.print("top: {d}, bottom: {d}, left: {d}, right: {d}, score: {d}\n", .{ top, bottom, left, right, top * bottom * left * right });

    return top * bottom * left * right;
}
