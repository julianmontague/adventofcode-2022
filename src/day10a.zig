//! Advent of Code 2022 Day 10 part 1 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const input_file = try input_cur_dir.openFile("day10.txt", .{});
    defer input_file.close();

    var buffer: [10]u8 = undefined;
    var wait = false;
    var X: i64 = 1;
    var sum: i64 = 0;
    var output: []const u8 = (try nextLine(input_file.reader(), &buffer)).?;

    for (1..221) |cycle| {
        // DEBUG try out.print("Cycle {d}\n", .{cycle});
        if ((cycle + 20) % 40 == 0) {
            sum = try updateSum(cycle, X, sum);
        }

        if (std.mem.count(u8, output, "addx") > 0) {
            if (wait) {
                X += try std.fmt.parseInt(i8, output[5..output.len], 10);
                // DEBUG try out.print("Finished waiting, at the end of this cycle X = {d}\n", .{X});
                output = (try nextLine(input_file.reader(), &buffer)).?;
                wait = false;
            } else {
                // DEBUG try out.writeAll("New add instruction, waiting...\n");
                wait = true;
            }
        } else if (std.mem.eql(u8, output, "noop")) {
            // DEBUG try out.writeAll("noop, doing nothing.\n");
            output = (try nextLine(input_file.reader(), &buffer)).?;
        } else {
            return error.UnknownInstruction;
        }
    }

    try out.print("Answer: {d}\n", .{sum});
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

pub fn updateSum(cycle: usize, X: i64, sum: i64) !i64 {
    const out = std.io.getStdOut().writer();
    const signal = @as(i64, @intCast(cycle)) * X;
    try out.print("Cycle #{d}, signal strength {d} * {d} = {d}. Sum: {d}\n", .{ cycle, cycle, X, signal, sum + signal });
    return sum + signal;
}
