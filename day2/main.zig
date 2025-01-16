const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const mem = std.mem;
const testing = std.testing;

const Allocator = std.mem.Allocator;

const Command = union(enum) {
    down: u8,
    forward: u8,
    up: u8,

    pub fn parse(raw: []const u8) !Command {
        var iter = mem.splitBackwardsScalar(u8, raw, ' ');

        const value = fmt.parseInt(u8, iter.next().?, 10) catch {
            return error.InvalidCommand;
        };

        const command = iter.next().?;

        if (mem.eql(u8, command, "down")) {
            return .{ .down = value };
        }

        if (mem.eql(u8, command, "forward")) {
            return .{ .forward = value };
        }

        if (mem.eql(u8, command, "up")) {
            return .{ .up = value };
        }

        return error.InvalidCommand;
    }
};

test "Command parsing" {
    const Case = struct {
        raw: []const u8,
        expected: anyerror!Command,
    };

    const cases = [_]Case{
        .{ .raw = "down 8", .expected = Command{ .down = 8 } },
        .{ .raw = "up 6", .expected = Command{ .up = 6 } },
        .{ .raw = "forward 9", .expected = Command{ .forward = 9 } },
        .{ .raw = "super 42", .expected = error.InvalidCommand },
        .{ .raw = "up two", .expected = error.InvalidCommand },
    };

    for (cases) |case| {
        const command = Command.parse(case.raw);
        try testing.expectEqual(case.expected, command);
    }
}

fn readDataFile(allocator: Allocator, path: []const u8) ![]u8 {
    const file = try fs.cwd().openFile(path, .{});
    defer file.close();

    const meta = try file.metadata();

    return file.readToEndAlloc(allocator, meta.size());
}

fn parseData(allocator: Allocator, data: []const u8) ![]Command {
    var commands = std.ArrayList(Command).init(allocator);

    var iter = std.mem.splitScalar(u8, data, '\n');
    while (iter.next()) |raw| {
        if (raw.len == 0) {
            continue;
        }

        const command = try Command.parse(raw);
        try commands.append(command);
    }

    return commands.toOwnedSlice();
}

fn partOne(allocator: Allocator, path: []const u8) !u32 {
    const data = try readDataFile(allocator, path);
    defer allocator.free(data);

    const commands = try parseData(allocator, data);
    defer allocator.free(commands);

    var depth: u32 = 0;
    var horizontalPosition: u32 = 0;

    for (commands) |command| {
        switch (command) {
            .down => |value| depth += value,
            .up => |value| depth -= value,
            .forward => |value| horizontalPosition += value,
        }
    }

    return depth * horizontalPosition;
}

fn partTwo(allocator: Allocator, path: []const u8) !u32 {
    const data = try readDataFile(allocator, path);
    defer allocator.free(data);

    const commands = try parseData(allocator, data);
    defer allocator.free(commands);

    var aim: u32 = 0;
    var depth: u32 = 0;
    var horizontalPosition: u32 = 0;

    for (commands) |command| {
        switch (command) {
            .down => |value| aim += value,
            .up => |value| aim -= value,
            .forward => |value| {
                horizontalPosition += value;
                depth += aim * value;
            },
        }
    }

    return depth * horizontalPosition;
}

test "Part one - Sample" {
    const count = try partOne(std.testing.allocator, "day2/sample.txt");
    try testing.expectEqual(150, count);
}

test "Part one - Input" {
    const count = try partOne(std.testing.allocator, "day2/input.txt");
    std.debug.print("Part one output: {}\n", .{count});
}

test "Part two - Sample" {
    const count = try partTwo(std.testing.allocator, "day2/sample.txt");
    try testing.expectEqual(900, count);
}

test "Part two - Input" {
    const count = try partTwo(std.testing.allocator, "day2/input.txt");
    std.debug.print("Part two output: {}\n", .{count});
}
