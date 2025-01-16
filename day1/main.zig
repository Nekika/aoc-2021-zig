const std = @import("std");
const fs = std.fs;
const testing = std.testing;

const Allocator = std.mem.Allocator;

fn readDataFile(allocator: Allocator, path: []const u8) ![]u8 {
    const file = try fs.cwd().openFile(path, .{});
    defer file.close();

    const meta = try file.metadata();

    return file.readToEndAlloc(allocator, meta.size());
}

fn parseData(allocator: Allocator, data: []const u8) ![]u16 {
    var measures = std.ArrayList(u16).init(allocator);

    var iter = std.mem.splitScalar(u8, data, '\n');
    while (iter.next()) |raw| {
        if (raw.len == 0) {
            continue;
        }

        const measure = try std.fmt.parseInt(u16, raw, 10);
        try measures.append(measure);
    }

    return measures.toOwnedSlice();
}

fn partOne(allocator: Allocator, path: []const u8) !u16 {
    const data = try readDataFile(allocator, path);
    defer allocator.free(data);

    const measures = try parseData(allocator, data);
    defer allocator.free(measures);

    var count: u16 = 0;

    var iter = std.mem.window(u16, measures, 2, 1);
    while (iter.next()) |window| {
        if (window[0] < window[1]) {
            count += 1;
        }
    }

    return count;
}

test "Part one - Sample" {
    const count = try partOne(std.testing.allocator, "day1/sample.txt");
    try testing.expectEqual(7, count);
}

test "Part one - Input" {
    const count = try partOne(std.testing.allocator, "day1/input.txt");
    std.debug.print("Part one output: {}\n", .{count});
}
