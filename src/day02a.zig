const std = @import("std");
const POINTS_LOSS = 0;
const POINTS_DRAW = 3;
const POINTS_WIN = 6;

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
        const me = output.?[2];
        var points = try resultPoints(opponent, me);
        points += switch (me) {
            'X' => 1,
            'Y' => 2,
            'Z' => 3,
            else => 0,
        };
        sum += points;
        try out.print("{c} {c}: {d}\n", .{ opponent, me, points });
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

pub fn resultPoints(p1: u8, p2: u8) error{InvalidMove}!u8 {
    if (p1 == 'A') {
        return switch (p2) {
            'X' => POINTS_DRAW,
            'Y' => POINTS_WIN,
            'Z' => POINTS_LOSS,
            else => error.InvalidMove,
        };
    } else if (p1 == 'B') {
        return switch (p2) {
            'X' => POINTS_LOSS,
            'Y' => POINTS_DRAW,
            'Z' => POINTS_WIN,
            else => error.InvalidMove,
        };
    } else if (p1 == 'C') {
        return switch (p2) {
            'X' => POINTS_WIN,
            'Y' => POINTS_LOSS,
            'Z' => POINTS_DRAW,
            else => error.InvalidMove,
        };
    } else {
        return error.InvalidMove;
    }
}
