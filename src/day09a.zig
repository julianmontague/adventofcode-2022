//! Advent of Code 2022 Day 9 part 1 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const Coords = struct { x: i32 = 0, y: i32 = 0 };
const HALF_WIDTH = 305;
const WIDTH = HALF_WIDTH * 2 + 1;

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const file = try input_cur_dir.openFile("day09.txt", .{});
    defer file.close();

    var buffer: [10]u8 = undefined;
    var head = Coords{};
    var tail = Coords{};
    var max = Coords{};
    var min = Coords{};
    var visited = [_][WIDTH]bool{.{false} ** WIDTH} ** WIDTH;
    visited[HALF_WIDTH][HALF_WIDTH] = true; // starting position of tail

    while (try nextLine(file.reader(), &buffer)) |output| {
        var move = Coords{};
        const length = try std.fmt.parseUnsigned(i8, output[2..output.len], 10);
        switch (output[0]) {
            'R' => {
                move.x = length;
            },
            'L' => {
                move.x = -length;
            },
            'U' => {
                move.y = length;
            },
            'D' => {
                move.y = -length;
            },
            else => {
                return error.UnknownDirection;
            },
        }

        try printCoords(head, tail);

        try out.print("Movement: ({d}, {d})\n", .{ move.x, move.y });

        if (move.x != 0) {
            const direction = std.math.sign(move.x);
            while (move.x != 0) : (move.x -= direction) {
                head.x += direction;
                tail = try getTailMovement(head, tail);
                visited[@intCast(HALF_WIDTH + tail.x)][@intCast(HALF_WIDTH + tail.y)] = true;
                saveExtrema(head, tail, &max, &min);
            }
        } else if (move.y != 0) {
            const direction = std.math.sign(move.y);
            while (move.y != 0) : (move.y -= direction) {
                head.y += direction;
                tail = try getTailMovement(head, tail);
                visited[@intCast(HALF_WIDTH + tail.x)][@intCast(HALF_WIDTH + tail.y)] = true;
                saveExtrema(head, tail, &max, &min);
            }
        }

        try printCoords(head, tail);
    }

    try out.print("Max: ({d}, {d}). Min: ({d}, {d})\n", .{ max.x, max.y, min.x, min.y });

    var visited_count: u64 = 0;
    for (visited) |row| {
        for (row) |visit| {
            if (visit) {
                visited_count += 1;
            }
        }
    }

    try out.print("Answer: {d}\n", .{visited_count});
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

pub fn getTailMovement(head: Coords, tail: Coords) !Coords {
    const x_diff = try std.math.absInt(head.x - tail.x);
    const y_diff = try std.math.absInt(head.y - tail.y);
    var new_tail = Coords{ .x = tail.x, .y = tail.y };
    if (x_diff > 1 or y_diff > 1) {
        const x_dir = std.math.sign(head.x - tail.x);
        const y_dir = std.math.sign(head.y - tail.y);
        new_tail.x += x_dir;
        new_tail.y += y_dir;
    }
    return new_tail;
}

pub fn printCoords(head: Coords, tail: Coords) !void {
    const out = std.io.getStdOut().writer();
    try out.print("Head: ({d}, {d}), Tail: ({d}, {d})\n", .{ head.x, head.y, tail.x, tail.y });
}

pub fn saveExtrema(head: Coords, tail: Coords, max: *Coords, min: *Coords) void {
    const max_x = @max(head.x, tail.x);
    const max_y = @max(head.y, tail.y);
    max.x = @max(max.x, max_x);
    max.y = @max(max.y, max_y);
    const min_x = @min(head.x, tail.x);
    const min_y = @min(head.y, tail.y);
    min.x = @min(min.x, min_x);
    min.y = @min(min.y, min_y);
}
