const std = @import("std");
const LOWERCASE_PRIORITY_CONV: u8 = 96;
const UPPERCASE_PRIORITY_CONV: u8 = 38;

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const inputDir = try std.fs.cwd().openDir("input", .{});
    const file = try inputDir.openFile("day03.txt", .{});
    defer file.close();

    var buffer: [100]u8 = undefined;
    var output: ?[]const u8 = try nextLine(file.reader(), &buffer);
    var sum: u64 = 0;

    while (output != null) {
        const length = output.?.len;
        const comp1 = output.?[0 .. length / 2];
        const comp2 = output.?[length / 2 .. length];
        const duplicate: u8 = try findDuplicateChar(comp1, comp2);
        var priority: u8 = undefined;
        if (std.ascii.isLower(duplicate)) {
            priority = duplicate - LOWERCASE_PRIORITY_CONV;
        } else {
            priority = duplicate - UPPERCASE_PRIORITY_CONV;
        }
        sum += priority;
        try out.print("{s}:{s} duplicate {c}\n", .{ comp1, comp2, duplicate });
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

pub fn findDuplicateChar(str1: []const u8, str2: []const u8) !u8 {
    for (str1) |char| {
        const charArr: [1]u8 = [_]u8{char};
        if (std.mem.count(u8, str2, &charArr) > 0) {
            return char;
        }
    }
    return error.NoDuplicate;
}
