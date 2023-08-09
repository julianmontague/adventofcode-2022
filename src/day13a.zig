//! Advent of Code 2022 Day 13 part 1 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const comma = ',';
const open_bracket = '[';
const close_bracket = ']';

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const input_file = try input_cur_dir.openFile("day13.txt", .{});
    defer input_file.close();

    var left_buffer: [250]u8 = undefined;
    var right_buffer: [250]u8 = undefined;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var index: u8 = 1;
    var sum: u16 = 0;

    while (try nextLine(input_file.reader(), &left_buffer)) |output| {
        if (output.len > 0) {
            const left = output;
            const right = (try nextLine(input_file.reader(), &right_buffer)).?;
            if ((try compareLists(left, right, allocator)).?) {
                sum += index;
            }
            index += 1;
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

pub fn compareLists(left: []const u8, right: []const u8, allocator: std.mem.Allocator) !?bool {
    var left_item: []const u8 = undefined;
    var right_item: []const u8 = undefined;
    // start past the opening bracket
    var left_index: usize = 1;
    var right_index: usize = 1;
    while (getNextListItem(left, left_index)) |left_item_info| {
        left_item = left_item_info.item;
        left_index = left_item_info.end_index + 1;
        if (getNextListItem(right, right_index)) |right_item_info| {
            right_item = right_item_info.item;
            right_index = right_item_info.end_index + 1;
            if (left_item[0] == open_bracket and right_item[0] == open_bracket) {
                // if both values are lists
                var comparison = try compareLists(left_item, right_item, allocator);
                if (comparison != null) {
                    return comparison;
                }
            } else if (left_item[0] != open_bracket and right_item[0] != open_bracket) {
                // if both values are ints
                const left_int = try std.fmt.parseUnsigned(u8, left_item, 10);
                const right_int = try std.fmt.parseUnsigned(u8, right_item, 10);
                if (left_int < right_int) {
                    return true;
                } else if (left_int > right_int) {
                    return false;
                }
                // "the inputs are the same integer;
                // continue checking the next part of the input."
            } else { // one item is an integer and the other is a list
                if (left_item[0] != open_bracket) {
                    const slices: []const []const u8 = &[_][]const u8{
                        &[1]u8{open_bracket},
                        left_item,
                        &[1]u8{close_bracket},
                    };
                    const left_list: []const u8 = try std.mem.concat(allocator, u8, slices);
                    var comparison = try compareLists(left_list, right_item, allocator);
                    if (comparison != null) {
                        return comparison;
                    }
                } else if (right_item[0] != open_bracket) {
                    const slices: []const []const u8 = &[_][]const u8{
                        &[1]u8{open_bracket},
                        right_item,
                        &[1]u8{close_bracket},
                    };
                    const right_list: []const u8 = try std.mem.concat(allocator, u8, slices);
                    var comparison = try compareLists(left_item, right_list, allocator);
                    if (comparison != null) {
                        return comparison;
                    }
                } else {
                    // at least one of the items isn't a list, but neither is an integer
                    // that doesn't make any sense; panic
                    unreachable;
                }
            }
        } else { // if there is no next right item
            // then the left list is longer than the right, the pair is out of order
            return false;
        }
    }
    // if there is no next left item, we need to check if there is a right one
    if (getNextListItem(right, right_index) != null) {
        // right list is longer than the left, the pair is in order
        return true;
    } else {
        // "If the lists are the same length and no comparison makes a decision about the order, continue checking the next part of the input."
        return null;
    }
}

pub const ItemInfo = struct {
    item: []const u8,
    end_index: usize,
};

pub fn getNextListItem(string: []const u8, start: usize) ?ItemInfo {
    if (start >= string.len) {
        return null;
    }
    var i: usize = start;
    var char = string[i];
    var brackets: u8 = 0;
    while (char != close_bracket and char != comma or brackets > 0) {
        if (char == open_bracket) {
            brackets += 1;
        } else if (char == close_bracket) {
            brackets -= 1;
        }
        i += 1;
        char = string[i];
    }
    if (i != start) { // there is an item
        return ItemInfo{ .item = string[start..i], .end_index = i };
    } else { // there is no item
        return null;
    }
}

test "getNextListItem empty list" {
    const output = getNextListItem("[]", 1);
    try std.testing.expect(output == null);
}

test "getNextListItem single item" {
    const output = getNextListItem("[1,[[2,5,7],8],6,4]", 15).?;
    try std.testing.expectEqualStrings("6", output.item);
}

test "getNextListItem last item" {
    const output = getNextListItem("[1,[[2,5,7],8],6,4]", 17).?;
    try std.testing.expectEqualStrings("4", output.item);
}

test "getNextListItem nested lists" {
    const output = getNextListItem("[1,[[2,5,7],8],6,4]", 3).?;
    try std.testing.expectEqualStrings("[[2,5,7],8]", output.item);
}

test "getNextListItem end of list" {
    const output = getNextListItem("[1,[[2,5,7],8],6,4]", 18);
    try std.testing.expect(output == null);
}

test "getNextListItem start out of bounds" {
    const output = getNextListItem("[1,[[2,5,7],8],6,4]", 19);
    try std.testing.expect(output == null);
}
