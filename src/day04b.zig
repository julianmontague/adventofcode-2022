const std = @import("std");
const hyphen = "-";
const comma = ",";

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const inputDir = try std.fs.cwd().openDir("input", .{});
    const file = try inputDir.openFile("day04.txt", .{});
    defer file.close();

    var buffer: [20]u8 = undefined;
    var output: ?[]const u8 = try nextLine(file.reader(), &buffer);
    var sum: u16 = 0;

    while (output != null) {
        const firstHyphen = std.mem.indexOf(u8, output.?, hyphen).?;
        const firstComma = std.mem.indexOf(u8, output.?, comma).?;
        const range1Start = try std.fmt.parseUnsigned(u8, output.?[0..firstHyphen], 10);
        const range1End = try std.fmt.parseUnsigned(u8, output.?[firstHyphen + 1 .. firstComma], 10);
        const secondHyphen = std.mem.indexOfPosLinear(u8, output.?, firstComma, hyphen).?;
        const range2Start = try std.fmt.parseUnsigned(u8, output.?[firstComma + 1 .. secondHyphen], 10);
        const range2End = try std.fmt.parseUnsigned(u8, output.?[secondHyphen + 1 .. output.?.len], 10);
        if (rangesOverlap(range1Start, range1End, range2Start, range2End)) {
            sum += 1;
        }
        try out.print("{s} Parsed: {d}-{d},{d}-{d}\n", .{ output.?, range1Start, range1End, range2Start, range2End });
        output = try nextLine(file.reader(), &buffer);
    }

    try out.print("Answer: {d} overlapping ranges\n", .{sum});
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

pub fn rangesOverlap(s1: u8, e1: u8, s2: u8, e2: u8) bool {
    if (s1 <= e2 and s1 >= s2) {
        return true;
    } else if (s2 <= e1 and s2 >= s1) {
        return true;
    } else {
        return false;
    }
}
