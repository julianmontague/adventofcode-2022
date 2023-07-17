//! Advent of Code 2022 Day 12 part 1 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const Node = struct { x: u8 = 0, y: u8 = 0, parent: ?usize = null };
const WIDTH = 161;
const HEIGHT = 41;
const start_char = 'S';
const end_char = 'E';
const directions = [4][2]i8{ [_]i8{ 1, 0 }, [_]i8{ -1, 0 }, [_]i8{ 0, 1 }, [_]i8{ 0, -1 } };

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const input_file = try input_cur_dir.openFile("day12.txt", .{});
    defer input_file.close();

    var buffer: [WIDTH + 1]u8 = undefined;
    var nodes: [HEIGHT][WIDTH]u8 = undefined;
    var explored = [_][WIDTH]bool{.{false} ** WIDTH} ** HEIGHT;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();
    var queue = std.ArrayList(Node).init(arena_allocator);
    var ancestors = std.ArrayList(Node).init(arena_allocator);
    var y: u8 = 0;
    var start = Node{};
    var end = Node{};

    while (try nextLine(input_file.reader(), &buffer)) |output| : (y += 1) {
        for (output, 0..) |char, x| {
            if (char == start_char) {
                nodes[y][x] = 'a';
                start.x = @intCast(x);
                start.y = y;
            } else if (char == end_char) {
                nodes[y][x] = 'z';
                end.x = @intCast(x);
                end.y = y;
            } else {
                nodes[y][x] = char;
            }
        }
    }

    // Breadth-first search
    explored[start.y][start.x] = true;
    try queue.append(start);
    while (queue.items.len > 0) {
        const node = queue.orderedRemove(0);
        if (node.x == end.x and node.y == end.y) {
            try out.print("Found end node at ({d}, {d})\n", .{ node.x, node.y });
            end = node;
            break;
        } else {
            try out.print("Exploring from ({d}, {d}):\n", .{ node.x, node.y });
            for (directions) |dir| {
                const test_x = @as(i16, @intCast(node.x)) + dir[0];
                const test_y = @as(i16, @intCast(node.y)) + dir[1];
                if (0 <= test_x and test_x < WIDTH and 0 <= test_y and test_y < HEIGHT) {
                    try out.print("Valid direction ({d}, {d}) ", .{ dir[0], dir[1] });
                    const new_x: u8 = @intCast(test_x);
                    const new_y: u8 = @intCast(test_y);
                    try out.print("brings us to ({d}, {d})\n", .{ new_x, new_y });
                    const height: i16 = nodes[node.y][node.x];
                    const new_height: i16 = nodes[new_y][new_x];
                    if (new_height - height <= 1) {
                        try out.writeAll("The node is within 1 level of height!\n");
                        if (!explored[new_y][new_x]) {
                            try out.print("Exploring node ({d}, {d})\n", .{ new_x, new_y });
                            explored[new_y][new_x] = true;
                            var parent_node = Node{
                                .x = node.x,
                                .y = node.y,
                                .parent = node.parent,
                            };
                            try ancestors.append(parent_node);
                            var new_node = Node{
                                .x = new_x,
                                .y = new_y,
                                .parent = ancestors.items.len - 1,
                            };
                            try queue.append(new_node);
                        }
                    }
                }
            }
        }
    }

    var node = end;
    var steps: u64 = 0;
    while (node.parent) |parent_id| {
        steps += 1;
        node = ancestors.items[parent_id];
    }

    try out.print("Answer: {d}\n", .{steps});
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
