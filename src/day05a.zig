const std = @import("std");
const COLUMN_WIDTH = 4;
const ROWS = 100;
const brackets: [2]u8 = [_]u8{ '[', ']' };
const space = ' ';
const space_arr: [1]u8 = [_]u8{space};

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_dir = try std.fs.cwd().openDir("input", .{});
    const file = try input_dir.openFile("day05.txt", .{});
    defer file.close();

    // skip all the crates until the column numbering
    try file.reader().skipUntilDelimiterOrEof('1');

    var buffer: [50]u8 = undefined;
    var output: ?[]const u8 = try nextLine(file.reader(), &buffer);
    const trimmed_output = std.mem.trimRight(u8, output.?, &space_arr);
    const last_char_arr: [1]u8 = [_]u8{trimmed_output[trimmed_output.len - 1]};
    const num_columns = try std.fmt.parseUnsigned(u8, &last_char_arr, 10);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var buffers = try allocator.alloc([ROWS]u8, num_columns);
    var fbas = try allocator.alloc(std.heap.FixedBufferAllocator, num_columns);
    var crate_table = try allocator.alloc(std.ArrayList(u8), num_columns);
    for (0..num_columns) |i| {
        fbas[i] = std.heap.FixedBufferAllocator.init(&buffers[i]);
        crate_table[i] = std.ArrayList(u8).init(fbas[i].allocator());
    }

    try file.seekTo(0);
    output = try nextLine(file.reader(), &buffer);

    // read the crates from the input
    while (output.?.len > 0 and output != null) : (output = try nextLine(file.reader(), &buffer)) {
        var crate_iterator = std.mem.splitAny(u8, output.?, &brackets);
        var crate = crate_iterator.next();
        var col: usize = 0;
        while (crate != null) : (crate = crate_iterator.next()) {
            const trimmed = std.mem.trim(u8, crate.?, &space_arr);
            if (trimmed.len == 1) {
                try out.print("Column: {d} Crate: {s}\n", .{ col, trimmed });
                try crate_table[col].append(trimmed[0]);
                col += 1;
            } else if (trimmed.len == 0) {
                const width = crate.?.len;
                const columns = width / COLUMN_WIDTH;
                col += columns;
            }
        }
        try out.writeAll("\n");
    }

    output = try nextLine(file.reader(), &buffer);
    // read the moves
    while (output != null) : (output = try nextLine(file.reader(), &buffer)) {
        var iterator = std.mem.splitScalar(u8, output.?, space);
        var item = iterator.next();
        var pos: u8 = 0;
        var moves: [3]u8 = undefined;
        while (item != null) : (item = iterator.next()) {
            if (std.ascii.isDigit(item.?[0])) {
                moves[pos] = try std.fmt.parseUnsigned(u8, item.?, 10);
                pos += 1;
            }
        }
        for (0..moves[0]) |i| {
            try out.print("Move #{d} from column {d} to column {d}\n", .{ i, moves[1], moves[2] });
            const crate = crate_table[moves[1] - 1].orderedRemove(0);
            try crate_table[moves[2] - 1].insert(0, crate);
        }
        try out.writeAll("\n");
    }

    try out.writeAll("Answer: ");
    for (0..num_columns) |i| {
        if (crate_table[i].items.len > 0) {
            try out.writeByte(crate_table[i].items[0]);
        }
    }
    try out.writeAll("\n");
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
