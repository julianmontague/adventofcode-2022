//! Advent of Code 2022 Day 9 part 2 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const Coords = struct { x: i32 = 0, y: i32 = 0 };
const KNOTS = 10;
const HALF_WIDTH = 305;
const WIDTH = HALF_WIDTH * 2 + 1;

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const input_file = try input_cur_dir.openFile("day09.txt", .{});
    defer input_file.close();
    const output_file = try std.fs.cwd().createFile("output.txt", .{});
    defer output_file.close();
    const file_out = output_file.writer();

    var buffer: [10]u8 = undefined;
    var knots = [_]Coords{Coords{}} ** KNOTS;
    var max = Coords{};
    var min = Coords{};
    var visited = [_][WIDTH]bool{.{false} ** WIDTH} ** WIDTH;
    visited[HALF_WIDTH][HALF_WIDTH] = true; // starting position of tail

    // DEBUG try printBoard(file_out, knots, visited);

    while (try nextLine(input_file.reader(), &buffer)) |output| {
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

        try file_out.print("Movement: ({d}, {d})\n", .{ move.x, move.y });

        if (move.x != 0) {
            const direction = std.math.sign(move.x);
            while (move.x != 0) : (move.x -= direction) {
                knots[0].x += direction;
                try moveKnots(&knots);
                const tail = knots[9];
                visited[@intCast(HALF_WIDTH + tail.y)][@intCast(HALF_WIDTH + tail.x)] = true;
                saveExtrema(knots[0], &max, &min);
                // DEBUG try printBoard(file_out, knots, visited);
            }
        } else if (move.y != 0) {
            const direction = std.math.sign(move.y);
            while (move.y != 0) : (move.y -= direction) {
                knots[0].y += direction;
                try moveKnots(&knots);
                const tail = knots[9];
                visited[@intCast(HALF_WIDTH + tail.y)][@intCast(HALF_WIDTH + tail.x)] = true;
                saveExtrema(knots[0], &max, &min);
                // DEBUG try printBoard(file_out, knots, visited);
            }
        }
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

    // DEBUG try printVisited(file_out, visited);

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

pub fn moveKnots(knots: *[KNOTS]Coords) !void {
    var prev_knot = knots[0];
    for (knots, 0..) |knot, i| {
        if (i == 0) {
            continue;
        }
        knots[i] = try getTailMovement(prev_knot, knot);
        prev_knot = knots[i];
    }
}

pub fn printBoard(out: std.fs.File.Writer, knots: [KNOTS]Coords, visited: [WIDTH][WIDTH]bool) !void {
    try out.writeAll(&([1]u8{'_'} ** WIDTH));
    try out.writeByte('\n');
    var board = [_][WIDTH]u8{.{'.'} ** WIDTH} ** WIDTH;
    board[HALF_WIDTH][HALF_WIDTH] = 's';
    for (0..KNOTS) |counter| {
        const i = KNOTS - 1 - counter;
        const knot = knots[i];
        var piece: u8 = '0' + @as(u8, @intCast(i));
        if (i == 0) {
            piece = 'H';
        }
        const x_pos: usize = @intCast(HALF_WIDTH + knot.x);
        const y_pos: usize = @intCast(HALF_WIDTH + knot.y);
        board[y_pos][x_pos] = piece;
    }
    for (0..WIDTH) |i| {
        const y = WIDTH - 1 - i;
        const row = board[y];
        for (row, 0..) |pos, x| {
            if (pos == '.' and visited[y][x]) {
                try out.writeByte('#');
            } else {
                try out.writeByte(pos);
            }
        }
        try out.writeByte('\n');
    }
}

pub fn printVisited(out: std.fs.File.Writer, visited: [WIDTH][WIDTH]bool) !void {
    try out.writeAll(&([1]u8{'_'} ** WIDTH));
    try out.writeByte('\n');
    for (0..WIDTH) |i| {
        const y = WIDTH - 1 - i;
        const row = visited[y];
        for (row, 0..) |visit, x| {
            var output: u8 = '.';
            if (x == HALF_WIDTH and y == HALF_WIDTH) {
                output = 's';
            } else if (visit) {
                output = '#';
            }
            try out.writeByte(output);
        }
        try out.writeByte('\n');
    }
}

pub fn saveExtrema(head: Coords, max: *Coords, min: *Coords) void {
    max.x = @max(max.x, head.x);
    max.y = @max(max.y, head.y);
    min.x = @min(min.x, head.x);
    min.y = @min(min.y, head.y);
}
