const std = @import("std");
const TOP_N = 3;

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const inputDir = try std.fs.cwd().openDir("input", .{});
    const file = try inputDir.openFile("day01.txt", .{});
    defer file.close();

    var buffer: [10]u8 = undefined;
    var output: []const u8 = undefined;
    var elf: u32 = 0;
    var max: u32 = 0;
    var oldMax: u32 = 0;
    var maxes: [TOP_N]u32 = undefined;

    for (0..TOP_N) |_| {
        try file.seekTo(0);
        while (!std.mem.eql(u8, output, "stop")) {
            output = (try nextLine(file.reader(), &buffer)) orelse "stop";
            const calories = std.fmt.parseUnsigned(u32, output, 10) catch 0;
            elf += calories;

            if (output.len == 0 or std.mem.eql(u8, output, "stop")) {
                if (!arrContains(&maxes, elf)) {
                    if (elf >= max) {
                        max = elf;
                        std.debug.print("New max: {d}\n", .{elf});
                    }
                }
                elf = 0;
            }
        }
        try out.print("Max this round: {d}\n", .{max});
        maxes = newMax(max);
        oldMax = max;
        max = 0;
        output = undefined;
    }

    var sum: u32 = 0;
    for (maxes) |val| {
        sum += val;
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

pub fn newMax(max: u32) [TOP_N]u32 {
    const S = struct {
        var list: [TOP_N]u32 = undefined;
    };
    if (S.list.len < TOP_N) {
        S.list[S.list.len] = max;
    } else {
        for (S.list, 0..) |_, i| {
            if (i + 1 < S.list.len) {
                S.list[i] = S.list[i + 1];
            }
        }
        S.list[S.list.len - 1] = max;
    }
    return S.list;
}

pub fn arrContains(arr: []u32, needle: u32) bool {
    for (arr) |val| {
        if (needle == val) {
            return true;
        }
    }
    return false;
}
