const std = @import("std");

const MAX_LINE_LENGTH = 14;
const NUM_WIDTH = u32;

pub fn main() !void {
    const stdin_file = std.io.getStdIn();
    var buf_reader = std.io.bufferedReader(stdin_file.reader());
    var in_stream = buf_reader.reader();

    var buf: [MAX_LINE_LENGTH]u8 = undefined;

    var left: [1000]NUM_WIDTH = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var right = std.AutoArrayHashMap(NUM_WIDTH, NUM_WIDTH).init(allocator);
    defer right.deinit();

    var line_count: u16 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const numbers = try parse_numbers(line, NUM_WIDTH);

        left[line_count] = numbers.left;

        const prev_count = right.get(numbers.right) orelse 0;
        try right.put(numbers.right, prev_count + 1);

        line_count += 1;
    }

    var sum: u64 = 0;
    for (left) |l| {
        sum += l * (right.get(l) orelse 0);
    }

    std.debug.print("{}", .{sum});
}

fn parse_numbers(line: []u8, comptime T: type) !struct { left: T, right: T } {
    const result = take_while_digit(line);
    const left = result[0];

    const rest = result[1];
    const remaining = skip_until_digit(rest);
    const right = take_while_digit(remaining);

    return .{ .left = try std.fmt.parseInt(T, left, 10), .right = try std.fmt.parseInt(T, right[0], 10) };
}

fn take_while_digit(rest: []u8) struct { []u8, []u8 } {
    if (rest.len > 1) {
        var index: u32 = 0;
        while (index < rest.len and is_digit(rest[index])) {
            index += 1;
        }

        if (index == 0) {
            unreachable;
        }

        return .{ rest[0..index], rest[index..] };
    } else {
        if (is_digit(rest[0])) {
            return .{ rest[0..1], &[_]u8{} };
        } else {
            return .{ &[_]u8{}, rest };
        }
    }
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

fn abs(a: u64, b: u64) u64 {
    return if (a > b) a - b else b - a;
}
