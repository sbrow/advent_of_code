const std = @import("std");

const MAX_LINE_LENGTH = 1024;

pub fn main() !void {
    // Open the file
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    // Create a buffered reader
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    // Create a buffer for reading lines
    var buf: [MAX_LINE_LENGTH]u8 = undefined;

    var sum: u64 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var game: Game = undefined;
        game.init();

        try game.parse(line);
        if (game.is_possible()) {
            // std.debug.print("{any}\n", .{game});

            sum += game.id;
        }
    }

    std.debug.print("{any}", .{sum});
}

const Game = struct {
    id: u8,
    max_red: u8,
    max_green: u8,
    max_blue: u8,

    fn init(target: *Game) void {
        target.* = .{
            .id = 0,
            .max_red = 0,
            .max_green = 0,
            .max_blue = 0,
        };
    }

    fn parse(self: *Game, line: []u8) !void {
        const result = take_while_digit(line[5..]);

        self.id = try std.fmt.parseInt(u8, result[0], 10);

        try self.parse_amounts(result[1][2..]);
    }

    fn parse_amounts(self: *Game, string: []u8) !void {
        var rest = string[0..];

        while (rest.len > 0) {
            const result = take_while_digit(rest);
            const amount = try std.fmt.parseInt(u8, result[0], 10);
            rest = result[1];

            const color: MarbleColor = @enumFromInt(rest[1]);

            rest = skip_until_digit(rest[1..]);

            self.set_max_color(color, amount);
        }
    }

    fn set_max_color(self: *Game, color: MarbleColor, amount: u8) void {
        switch (color) {
            .red => {
                if (amount > self.max_red) {
                    self.max_red = amount;
                }
            },
            .green => {
                if (amount > self.max_green) {
                    self.max_green = amount;
                }
            },
            .blue => {
                if (amount > self.max_blue) {
                    self.max_blue = amount;
                }
            },
        }
    }

    fn is_possible(self: Game) bool {
        return self.max_red <= 12 and self.max_green <= 13 and self.max_blue <= 14;
    }
};

const MarbleColor = enum(u8) { red = 'r', green = 'g', blue = 'b' };

fn take_while_digit(rest: []u8) struct { []u8, []u8 } {
    var index: u32 = 0;
    while (is_digit(rest[index])) {
        index += 1;
    }

    if (index == 0) {
        unreachable;
    }

    return .{ rest[0..index], rest[index..] };
}

fn is_digit(char: u64) bool {
    return char > 47 and char < 58;
}

fn skip_until_digit(rest: []u8) []u8 { // u64 {
    var index: u32 = 0;
    while (index < rest.len) : (index += 1) {
        if (is_digit(rest[index])) {
            if (index > 0) {
                return rest[index..];
            } else {
                unreachable;
            }
        }
    }

    return &[_]u8{};
}

const expect = std.testing.expect;
test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "function parameters" {
    const input = [_]u8{ '1', '2', '3', 'f', 'o', 'o' };
    const result = skip_while(is_digit, @constCast(&input));

    try expect(result[0] == 'f');
    try expect(result[1] == 'o');
    try expect(result[2] == 'o');
}

fn skip_while(comptime predicate: fn (u64) bool, string: []u8) []u8 {
    var index: u64 = 0;
    while (index < string.len and predicate(string[index])) {
        index += 1;
    }

    return string[index..];
}
