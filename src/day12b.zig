//! Advent of Code 2022 Day 12 part 2 solution
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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();
    var minima = std.ArrayList(Node).init(arena_allocator);
    var y: u8 = 0;
    var start = Node{};
    var end = Node{};

    while (try nextLine(input_file.reader(), &buffer)) |output| : (y += 1) {
        for (output, 0..) |char, x| {
            if (char == start_char) {
                nodes[y][x] = 'a';
                start.x = @intCast(x);
                start.y = y;
                try minima.append(start);
            } else if (char == end_char) {
                nodes[y][x] = 'z';
                end.x = @intCast(x);
                end.y = y;
            } else {
                nodes[y][x] = char;
                if (char == 'a') {
                    var node = Node{ .x = @intCast(x), .y = y };
                    try minima.append(node);
                }
            }
        }
    }

    var min_steps: u64 = std.math.maxInt(u64);
    for (minima.items) |minimum| {
        const steps = shortestPath(minimum, end, nodes, arena_allocator) catch std.math.maxInt(u64);
        min_steps = @min(min_steps, steps);
    }

    try out.print("Answer: {d}\n", .{min_steps});
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

pub fn shortestPath(start: Node, end: Node, nodes: [HEIGHT][WIDTH]u8, allocator: std.mem.Allocator) !u64 {
    var explored = [_][WIDTH]bool{.{false} ** WIDTH} ** HEIGHT;
    var queue = std.ArrayList(Node).init(allocator);
    var ancestors = std.ArrayList(Node).init(allocator);
    var end_node_found = false;
    var end_node: Node = undefined;

    // Breadth-first search
    explored[start.y][start.x] = true;
    try queue.append(start);
    while (queue.items.len > 0) {
        const node = queue.orderedRemove(0);
        if (node.x == end.x and node.y == end.y) {
            end_node_found = true;
            end_node = node;
            break;
        } else {
            for (directions) |dir| {
                const test_x = @as(i16, @intCast(node.x)) + dir[0];
                const test_y = @as(i16, @intCast(node.y)) + dir[1];
                if (0 <= test_x and test_x < WIDTH and 0 <= test_y and test_y < HEIGHT) {
                    const new_x: u8 = @intCast(test_x);
                    const new_y: u8 = @intCast(test_y);
                    const height: i16 = nodes[node.y][node.x];
                    const new_height: i16 = nodes[new_y][new_x];
                    if (new_height - height <= 1) {
                        if (!explored[new_y][new_x]) {
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

    var steps: u64 = 0;
    if (end_node_found) {
        while (end_node.parent) |parent_id| {
            steps += 1;
            end_node = ancestors.items[parent_id];
        }
    } else {
        return error.NoPathFound;
    }

    return steps;
}
