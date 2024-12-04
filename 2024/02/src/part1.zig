const std = @import("std");

const MAX_LINE_LENGTH = 24;

pub fn main() !void {
    const stdin_file = std.io.getStdIn();
    var buf_reader = std.io.bufferedReader(stdin_file.reader());
    var in_stream = buf_reader.reader();

    var buf: [MAX_LINE_LENGTH]u8 = undefined;

    var sum: u32 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // std.debug.print("{s}\n", .{line});
        if (try is_safe(line)) {
            sum += 1;
            // std.debug.print(" OK!", .{});
        }
        // std.debug.print("\n", .{});
    }

    std.debug.print("{}", .{sum});
}

fn is_safe(report: []u8) !bool {
    var remaining = report;
    var left: i32 = undefined;
    var right: i32 = undefined;

    left, remaining = try parse_int(remaining);
    _, remaining = skip_until_digit(remaining);
    right, remaining = try parse_int(remaining);

    const incrementing = left < right;
    var safe = are_safe(left, right, incrementing);

    // std.debug.print("{s} ", .{if (incrementing) "+" else "-"});

    while (safe and remaining.len > 0) {
        // std.debug.print("({}, {}) ", .{ left, right });

        left = right;

        _, remaining = skip_until_digit(remaining);
        right, remaining = try parse_int(remaining);

        safe = are_safe(left, right, incrementing);
    }

    return safe;
}

fn are_safe(left: i32, right: i32, incrementing: bool) bool {
    const delta = if (incrementing)
        right - left
    else
        left - right;

    return delta > 0 and delta < 4;
}

fn parse_int(
    rest: []u8,
) !struct { i32, []u8 } {
    const results = take_while_digit(rest);

    return .{ try std.fmt.parseInt(i32, results[0], 10), results[1] };
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

fn skip_until_digit(rest: []u8) struct { void, []u8 } { // u64 {
    var index: u32 = 0;
    while (index < rest.len) : (index += 1) {
        if (is_digit(rest[index])) {
            if (index > 0) {
                return .{ {}, rest[index..] };
            } else {
                unreachable;
            }
        }
    }

    return .{ {}, &[_]u8{} };
}

test "take_while_digit" {
    const input = "837.152";
    const result = take_while_digit(@constCast(input));
    try std.testing.expectEqualSlices(u8, "837", result[0]);
    try std.testing.expectEqualSlices(u8, ".152", result[1]);
}
