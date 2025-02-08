const std = @import("std");

const Allocator = std.mem.Allocator;

const input = @embedFile("input.txt");
const sample = @embedFile("sample.txt");

const Cell = struct {
    marked: bool,
    value: u8,

    const Self = @This();

    pub fn mark(self: *Self) void {
        self.marked = true;
    }
};

const Grid = struct {
    cells: [5][5]Cell,

    const Self = @This();

    pub fn check(self: *Self, value: u8) bool {
        for (0..5) |row| {
            for (0..5) |col| {
                var cell = &self.cells[row][col];
                if (cell.value == value) {
                    cell.mark();
                    return true;
                }
            }
        }

        return false;
    }

    pub fn won(self: Self) bool {
        for (0..5) |row| {
            for (0..5) |col| {
                const cell = self.cells[row][col];
                if (!cell.marked) break;
                if (col == 4) return true;
            }
        }

        for (0..5) |col| {
            for (0..5) |row| {
                const cell = self.cells[row][col];
                if (!cell.marked) break;
                if (row == 4) return true;
            }
        }

        return false;
    }

    pub fn score(self: Self) u32 {
        var total: u32 = 0;

        for (0..5) |row| {
            for (0..5) |col| {
                const cell = self.cells[row][col];
                if (!cell.marked) {
                    total += cell.value;
                }
            }
        }

        return total;
    }
};

fn parseGrid(bytes: []const u8) !Grid {
    var cells: [5][5]Cell = undefined;

    var begin: usize = 0;
    for (0..5) |row| {
        for (0..5) |col| {
            const end = begin + 2;
            const raw = std.mem.trim(u8, bytes[begin..end], " ");
            const value = try std.fmt.parseInt(u8, raw, 10);
            cells[row][col] = Cell{ .marked = false, .value = value };
            begin = end + 1;
        }
    }

    return Grid{ .cells = cells };
}

fn parseGrids(allocator: Allocator, bytes: []const u8) ![]Grid {
    var grids = std.ArrayList(Grid).init(allocator);

    var iter = std.mem.splitSequence(u8, bytes, "\n\n");
    while (iter.next()) |block| {
        const grid = try parseGrid(block);
        try grids.append(grid);
    }

    return grids.toOwnedSlice();
}

fn parseNumbers(allocator: Allocator, bytes: []const u8) ![]u8 {
    var numbers = std.ArrayList(u8).init(allocator);

    var iter = std.mem.splitScalar(u8, bytes, ',');
    while (iter.next()) |raw| {
        const number = try std.fmt.parseInt(u8, raw, 10);
        try numbers.append(number);
    }

    return numbers.toOwnedSlice();
}

fn partOne(allocator: Allocator, bytes: []const u8) !u32 {
    const trimmed = std.mem.trim(u8, bytes, "\n");

    var parts = std.mem.splitSequence(u8, trimmed, "\n\n");

    const numbers = try parseNumbers(allocator, parts.next().?);
    defer allocator.free(numbers);

    const grids = try parseGrids(allocator, parts.rest());
    defer allocator.free(grids);

    for (0..numbers.len) |index| {
        for (grids) |*grid| {
            const marked = grid.check(numbers[index]);
            if (index < 4) continue;
            if (marked and grid.won()) {
                return numbers[index] * grid.score();
            }
        }
    }

    return error.NoWinner;
}

test "Part one - Sample" {
    const score = try partOne(std.testing.allocator, sample);
    try std.testing.expectEqual(4512, score);
}

test "Part one - Input" {
    const score = try partOne(std.testing.allocator, input);
    std.debug.print("Score: {}\n", .{score});
}
