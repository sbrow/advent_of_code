const std = @import("std");

const MAX_LINE_LENGTH = 14;

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdin_file = std.io.getStdIn();
    var buf_reader = std.io.bufferedReader(stdin_file.reader());
    var in_stream = buf_reader.reader();

    var buf: [MAX_LINE_LENGTH]u8 = undefined;

    var left: [1000]u64 = undefined;
    var right: [1000]u64 = undefined;

    var line_count: u16 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const numbers = try parse_numbers(line);

        left[line_count] = numbers.left;
        right[line_count] = numbers.right;

        // std.debug.print("line: {}\n", .{line_count});
        line_count += 1;
    }

    std.mem.sort(u64, &left, {}, comptime std.sort.asc(u64));
    std.mem.sort(u64, &right, {}, comptime std.sort.asc(u64));
    // std.debug.print("left: {any}\n", .{left});
    // std.debug.print("right: {any}\n\n", .{right});

    var sum: u64 = 0;
    for (left, 0..) |_, i| {
        // std.debug.print("{}\n", .{abs(left[i], right[i])});

        sum += abs(left[i], right[i]);
    }

    std.debug.print("{}", .{sum});
}

fn parse_numbers(line: []u8) !struct { left: u64, right: u64 } {
    const result = take_while_digit(line);
    const left = result[0];

    const rest = result[1];
    const remaining = skip_until_digit(rest);
    const right = take_while_digit(remaining);

    return .{ .left = try std.fmt.parseInt(u64, left, 10), .right = try std.fmt.parseInt(u64, right[0], 10) };
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
