//! Advent of Code 2022 Day 13 part 2 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const comma = ',';
const open_bracket = '[';
const close_bracket = ']';
const divider1 = "[[2]]";
const divider2 = "[[6]]";

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const input_file = try input_cur_dir.openFile("day13.txt", .{});
    defer input_file.close();
    const output_file = try std.fs.cwd().createFile("output.txt", .{});
    defer output_file.close();
    const file_out = output_file.writer();

    var buffer: [250]u8 = undefined;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var buf_map = std.BufMap.init(allocator);
    defer buf_map.deinit();
    var sorted = std.ArrayList([]const u8).init(allocator);
    defer sorted.deinit();
    var sum: u16 = 1;

    try sorted.append(divider1);
    try sorted.append(divider2);

    while (try nextLine(input_file.reader(), &buffer)) |new_item| {
        if (new_item.len > 0) {
            // insertion sort
            var inserted = false;
            std.debug.assert(std.math.maxInt(i128) > std.math.maxInt(usize));
            var counter: i128 = sorted.items.len - 1;
            while (!inserted and counter >= 0) : (counter -= 1) {
                const i: usize = @intCast(counter);
                const item = sorted.items[i];
                if ((try compareLists(item, new_item, allocator)).?) {
                    try copyInsert(&sorted, &buf_map, i + 1, new_item);
                    inserted = true;
                }
            }
            if (!inserted) {
                // if it still hasn't been inserted, it should be all the way to the left
                try copyInsert(&sorted, &buf_map, 0, new_item);
            }
        }
    }

    for (sorted.items, 1..) |item, i| {
        try file_out.print("{s}\n", .{item});
        if (std.mem.eql(u8, item, divider1) or std.mem.eql(u8, item, divider2)) {
            sum *= @intCast(i);
        }
    }

    try out.print("Answer: {d}\n", .{sum});
}

pub fn copyInsert(array_list: *std.ArrayList([]const u8), buf_map: *std.BufMap, n: usize, item: []const u8) !void {
    var item_copy: []const u8 = undefined;
    if (buf_map.*.get(item)) |value| {
        item_copy = value;
    } else {
        try buf_map.*.put(item, item);
        item_copy = buf_map.*.get(item).?;
    }
    try array_list.*.insert(n, item_copy);
}

test "copyInsert actually increases the size of the ArrayList" {
    var array_list = std.ArrayList([]const u8).init(std.testing.allocator);
    defer array_list.deinit();
    var buf_map = std.BufMap.init(std.testing.allocator);
    defer buf_map.deinit();
    try std.testing.expectEqual(@as(usize, 0), array_list.items.len);
    try copyInsert(&array_list, &buf_map, 0, "test1");
    try std.testing.expectEqual(@as(usize, 1), array_list.items.len);
    try copyInsert(&array_list, &buf_map, 0, "test2");
    try std.testing.expectEqual(@as(usize, 2), array_list.items.len);
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
