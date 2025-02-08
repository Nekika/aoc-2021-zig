const std = @import("std");

const Allocator = std.mem.Allocator;

const sample = @embedFile("sample.txt");
const input = @embedFile("input.txt");

fn parse(allocator: Allocator, data: []const u8) ![][]u32 {
    var al = std.ArrayList([]u32).init(allocator);

    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        try al.append(try parseLine(allocator, line));
    }

    return al.toOwnedSlice();
}

fn parseBit(char: u8) !u32 {
    return switch (char) {
        '0' => 0,
        '1' => 1,
        else => error.InvalidBit,
    };
}
fn parseLine(allocator: Allocator, line: []const u8) ![]u32 {
    var al = std.ArrayList(u32).init(allocator);

    for (line) |char| {
        try al.append(try parseBit(char));
    }

    return al.toOwnedSlice();
}

fn partOne(allocator: Allocator, data: []const u8) !u32 {
    const lines = try parse(allocator, data);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    const half: u32 = @as(u32, @intCast(lines.len)) / 2;

    var sums = try allocator.alloc(u32, lines[0].len);
    defer allocator.free(sums);

    for (sums, 0..) |_, index| {
        sums[index] = 0;
    }

    for (lines) |bits| {
        for (bits, 0..) |bit, index| {
            sums[index] += bit;
        }
    }

    var gamma: u32 = 0;
    for (sums) |sum| {
        const bit: u32 = if (sum > half) 1 else 0;
        gamma = (gamma << 1) + bit;
    }

    var epsilon: u32 = 0;
    for (sums) |sum| {
        const bit: u32 = if (sum > half) 0 else 1;
        epsilon = (epsilon << 1) + bit;
    }

    return gamma * epsilon;
}

test "Part one - Sample" {
    const consumption = try partOne(std.testing.allocator, sample);
    try std.testing.expectEqual(198, consumption);
}

test "Part one - Input" {
    const consumption = try partOne(std.testing.allocator, input);
    std.debug.print("Power consumption: {}\n", .{consumption});
}
