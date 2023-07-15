//! Advent of Code 2022 Day 11 part 1 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const NUM_MONKEYS = 8;
const Test = struct {
    divisible: u8 = 0,
    true: u8 = 0,
    false: u8 = 0,
};
const Monkey = struct {
    items: std.ArrayList(u32),
    op: u8 = 'u',
    op_num: u16 = 0,
    op_old: bool = false,
    the_test: Test,
    inspections: u64 = 0,
};

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const input_file = try input_cur_dir.openFile("day11.txt", .{});
    defer input_file.close();

    var buffer: [100]u8 = undefined;
    var monkeys: [NUM_MONKEYS]Monkey = undefined;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var index: usize = 0;

    while (try nextLine(input_file.reader(), &buffer)) |output| {
        if (output.len == 0) {
            continue;
        }

        const trimmed = std.mem.trimLeft(u8, output, " ");

        if (std.mem.eql(u8, trimmed[0..6], "Monkey")) {
            index = try std.fmt.parseUnsigned(u8, trimmed[7 .. trimmed.len - 1], 10);
        } else if (std.mem.eql(u8, trimmed[0..14], "Starting items")) {
            var items = std.ArrayList(u32).init(arena.allocator());
            var iterator = std.mem.splitSequence(u8, trimmed[16..trimmed.len], ", ");
            while (iterator.next()) |item| {
                const parsed = try std.fmt.parseUnsigned(u8, item, 10);
                try items.append(parsed);
            }
            monkeys[index] = Monkey{ .items = items, .the_test = Test{} };
        } else if (std.mem.eql(u8, trimmed[0..9], "Operation")) {
            monkeys[index].op = trimmed[21];
            if (std.mem.eql(u8, trimmed[23..trimmed.len], "old")) {
                monkeys[index].op_old = true;
            } else {
                const num = try std.fmt.parseUnsigned(u8, trimmed[23..trimmed.len], 10);
                monkeys[index].op_num = num;
            }
        } else if (std.mem.eql(u8, trimmed[0..4], "Test")) {
            if (std.mem.eql(u8, trimmed[6..18], "divisible by")) {
                const cond_num = try std.fmt.parseUnsigned(u8, trimmed[19..trimmed.len], 10);
                monkeys[index].the_test.divisible = cond_num;
            } else {
                return error.UnknownTestCondition;
            }
        } else if (std.mem.eql(u8, trimmed[0..7], "If true")) {
            const monkey_num = try std.fmt.parseUnsigned(u8, trimmed[25..trimmed.len], 10);
            monkeys[index].the_test.true = monkey_num;
        } else if (std.mem.eql(u8, trimmed[0..8], "If false")) {
            const monkey_num = try std.fmt.parseUnsigned(u8, trimmed[26..trimmed.len], 10);
            monkeys[index].the_test.false = monkey_num;
        }
    }

    for (0..20) |_| {
        for (monkeys, 0..) |monkey, i| {
            while (monkeys[i].items.items.len > 0) {
                monkeys[i].inspections += 1;
                var thrown = monkeys[i].items.orderedRemove(0);
                if (monkey.op_old) {
                    if (monkey.op == '*') {
                        thrown *= thrown;
                    } else if (monkey.op == '+') {
                        thrown += thrown;
                    } else {
                        return error.UnknownOperator;
                    }
                } else {
                    if (monkey.op == '*') {
                        thrown *= monkey.op_num;
                    } else if (monkey.op == '+') {
                        thrown += monkey.op_num;
                    } else {
                        return error.UnknownOperator;
                    }
                }
                thrown /= 3;
                var throw_to: u8 = undefined;
                if (thrown % monkey.the_test.divisible == 0) {
                    throw_to = monkey.the_test.true;
                } else {
                    throw_to = monkey.the_test.false;
                }
                try monkeys[throw_to].items.append(thrown);
            }
        }
    }

    // DEBUG print all monkeys in the input format
    // for (monkeys, 0..) |monkey, i| {
    //     try printMonkey(i, monkey);
    //     try out.writeByte('\n');
    // }

    var max_1: u64 = 0;
    var max_1_i: usize = undefined;
    var max_2: u64 = 0;

    for (monkeys, 0..) |monkey, i| {
        if (monkey.inspections > max_1) {
            max_1 = monkey.inspections;
            max_1_i = i;
        }
    }

    for (monkeys, 0..) |monkey, i| {
        if (i != max_1_i and monkey.inspections > max_2) {
            max_2 = monkey.inspections;
        }
    }

    const monkey_business = max_1 * max_2;

    try out.print("Answer: {d}\n", .{monkey_business});
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

pub fn printMonkey(id: usize, monkey: Monkey) !void {
    const out = std.io.getStdOut().writer();
    try out.print("Monkey {d}:\n", .{id});

    try out.writeAll("  Starting items: ");
    const length = monkey.items.items.len;
    for (monkey.items.items, 0..) |item, i| {
        try out.print("{d}", .{item});
        if (i < length - 1) {
            try out.writeAll(", ");
        }
    }
    try out.writeByte('\n');

    try out.print("  Operation: new = old {c} ", .{monkey.op});

    if (monkey.op_old) {
        try out.writeAll("old\n");
    } else {
        try out.print("{d}\n", .{monkey.op_num});
    }

    try out.print("  Test: divisible by {d}\n", .{monkey.the_test.divisible});

    try out.print("    If true: throw to monkey {d}\n", .{monkey.the_test.true});

    try out.print("    If false: throw to monkey {d}\n", .{monkey.the_test.false});
}
