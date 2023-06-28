//! Advent of Code 2022 Day 2 part 2 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const POINTS_ROCK: u8 = 1;
const POINTS_PAPER: u8 = 2;
const POINTS_SCISSORS: u8 = 3;
const POINTS_LOSS: u8 = 0;
const POINTS_DRAW: u8 = 3;
const POINTS_WIN: u8 = 6;
const MOVE_ROCK: u8 = 'A';
const MOVE_PAPER: u8 = 'B';
const MOVE_SCISSORS: u8 = 'C';
const STRAT_LOSE: u8 = 'X';
const STRAT_DRAW: u8 = 'Y';
const STRAT_WIN: u8 = 'Z';

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const inputDir = try std.fs.cwd().openDir("input", .{});
    const file = try inputDir.openFile("day02.txt", .{});
    defer file.close();

    var buffer: [10]u8 = undefined;
    var output: ?[]const u8 = try nextLine(file.reader(), &buffer);
    var sum: u64 = 0;

    while (output != null) {
        const opponent = output.?[0];
        const strategy = output.?[2];
        const points = try resultPoints(opponent, strategy);
        sum += points;
        try out.print("{c} {c}: {d}\n", .{ opponent, strategy, points });
        output = try nextLine(file.reader(), &buffer);
    }

    try out.print("Answer: {d} points\n", .{sum});
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

pub fn resultPoints(p1: u8, strat: u8) error{ InvalidMove, InvalidStrategy }!u8 {
    if (strat == STRAT_WIN) {
        return POINTS_WIN + switch (p1) {
            MOVE_ROCK => POINTS_PAPER,
            MOVE_PAPER => POINTS_SCISSORS,
            MOVE_SCISSORS => POINTS_ROCK,
            else => return error.InvalidMove,
        };
    } else if (strat == STRAT_DRAW) {
        return POINTS_DRAW + switch (p1) {
            MOVE_ROCK => POINTS_ROCK,
            MOVE_PAPER => POINTS_PAPER,
            MOVE_SCISSORS => POINTS_SCISSORS,
            else => return error.InvalidMove,
        };
    } else if (strat == STRAT_LOSE) {
        return POINTS_LOSS + switch (p1) {
            MOVE_ROCK => POINTS_SCISSORS,
            MOVE_PAPER => POINTS_ROCK,
            MOVE_SCISSORS => POINTS_PAPER,
            else => return error.InvalidMove,
        };
    } else {
        return error.InvalidStrategy;
    }
}
