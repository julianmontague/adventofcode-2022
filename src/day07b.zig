//! Advent of Code 2022 Day 7 part 2 solution
//! Copyright 2023 Julian Montague
//! SPDX-License-Identifier: GPL-3.0-or-later

const std = @import("std");
const TOTAL_SPACE = 70000000;
const AVAIL_SPACE = 40000000;

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    const input_cur_dir = try std.fs.cwd().openDir("input", .{});
    const file = try input_cur_dir.openFile("day07.txt", .{});
    defer file.close();

    var buffer1: [100]u8 = undefined;
    var buffer2: [100]u8 = undefined;
    var cur_dir: []const u8 = "";
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();
    const Dir = struct { size: u64, subdirs: std.ArrayList([]const u8) };
    var dirs = std.StringHashMap(Dir).init(arena_allocator);
    defer {
        var iterator = dirs.iterator();
        while (iterator.next()) |res| {
            res.value_ptr.*.subdirs.deinit();
        }
        dirs.deinit();
    }
    var buf_map = std.BufMap.init(arena_allocator);
    defer buf_map.deinit();
    var known_sizes = std.BufSet.init(arena_allocator);
    defer known_sizes.deinit();

    while (try nextLine(file.reader(), &buffer1)) |output| {
        if (output[0] == '$') {
            if (output[2] == 'c') {
                if (output[5] == '.') {
                    const index = std.mem.lastIndexOf(u8, cur_dir, "/").?;
                    cur_dir = cur_dir[0..index];
                } else if (output[5] == '/') {
                    cur_dir = "";
                } else {
                    const dir = output[5..output.len];
                    cur_dir = pathConcat(cur_dir, dir, &buffer2);
                }
            }
        } else {
            const key = try getOrPutBufMap(&buf_map, cur_dir);
            var res = try dirs.getOrPut(key);
            var dir: Dir = undefined;
            if (!res.found_existing) {
                dir = Dir{
                    .size = 0,
                    .subdirs = std.ArrayList([]const u8).init(arena_allocator),
                };
                res.value_ptr.* = dir;
            } else {
                dir = res.value_ptr.*;
            }
            var iterator = std.mem.splitScalar(u8, output, ' ');
            if (output[0] == 'd') {
                var subdir = iterator.next().?;
                subdir = iterator.next().?;
                const subdir_key = try getOrPutBufMap(&buf_map, subdir);
                try dir.subdirs.append(subdir_key);
                try dirs.put(key, dir);
            } else {
                dir.size += try std.fmt.parseUnsigned(u64, iterator.first(), 10);
                try dirs.put(key, dir);
            }
        }
    }

    var iterator = dirs.iterator();
    while (iterator.next()) |res| {
        const dir_name = res.key_ptr.*;
        const dir = res.value_ptr.*;
        try out.print("Directory '{s}' has size {d} and ", .{ dir_name, dir.size });
        if (dir.subdirs.items.len > 0) {
            try out.writeAll("sub-directories: ");
            for (dir.subdirs.items) |subdir| {
                try out.print("{s}, ", .{subdir});
            }
        } else {
            try out.writeAll("no sub-directories");
            try known_sizes.insert(dir_name);
        }
        try out.writeByte('\n');
    }

    while (known_sizes.count() < dirs.count()) {
        iterator = dirs.iterator();
        while (iterator.next()) |res| {
            const dir_name = res.key_ptr.*;
            var dir = res.value_ptr.*;
            if (!known_sizes.contains(dir_name)) {
                var size_known = true;
                for (dir.subdirs.items) |subdir_name| {
                    const full_subdir_name = pathConcat(dir_name, subdir_name, &buffer2);
                    if (!known_sizes.contains(full_subdir_name)) {
                        size_known = false;
                    }
                }
                if (size_known) {
                    for (dir.subdirs.items) |subdir_name| {
                        const full_subdir_name = pathConcat(dir_name, subdir_name, &buffer2);
                        const subdir = dirs.get(full_subdir_name).?;
                        dir.size += subdir.size;
                    }
                    try dirs.put(dir_name, dir);
                    try known_sizes.insert(dir_name);
                }
            }
        }
    }

    const used_space = dirs.get("").?.size;
    const needed_space = used_space - AVAIL_SPACE;
    try out.print("Used space: {d}. Needed space: {d}\n", .{ used_space, needed_space });

    var min: u64 = TOTAL_SPACE;
    var value_iterator = dirs.valueIterator();
    while (value_iterator.next()) |res| {
        const dir = res.*;
        if (dir.size >= needed_space and dir.size < min) {
            try out.print("New smallest folder {d}\n", .{dir.size});
            min = dir.size;
        }
    }

    try out.print("Answer: {d}\n", .{min});
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

pub fn pathConcat(str1: []const u8, str2: []const u8, buffer: []u8) []const u8 {
    const index = str1.len + 1;
    std.mem.copyForwards(u8, buffer[0..str1.len], str1);
    @memcpy(buffer[str1.len..index], "/");
    @memcpy(buffer[index .. index + str2.len], str2);
    return buffer[0 .. index + str2.len];
}

pub fn getOrPutBufMap(buf_map: *std.BufMap, key: []const u8) ![]const u8 {
    var actual_buf_map = buf_map.*;
    if (actual_buf_map.get(key)) |the_key| {
        return the_key;
    } else {
        try actual_buf_map.put(key, key);
        return actual_buf_map.get(key).?;
    }
}
