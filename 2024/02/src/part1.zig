const std = @import("std");

const MAX_LINE_LENGTH = 24;

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdin_file = std.io.getStdIn();
    var buf_reader = std.io.bufferedReader(stdin_file.reader());
    var in_stream = buf_reader.reader();

    var buf: [MAX_LINE_LENGTH]u8 = undefined;

    var sum: u32 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (is_safe(line)) {
            sum += 1;
        }
    }

    std.debug.print("{}", .{sum});
}

fn is_safe(report: []u8) bool {
    const results = space_delimited_numbers(report);

    std.debug.print("({s}, {s})...{s}\n", .{ results[0], results[1], results[2] });

    return true;
}

const space_delimited_numbers = delimited(
    []u8,
    []u8,
    take_while_digit,
    skip_until_digit,
    take_while_digit,
);

fn delimited(
    // Help
    comptime T: type,
    comptime U: type,
    comptime first: Parser(T),
    comptime second: Parser(void),
    comptime third: Parser(U),
    // ) Parser(struct { T, U }) {
) fn (input: []u8) struct { T, U, []u8 } {
    return struct {
        pub fn invoke(bytes: []u8) struct { T, U, []u8 } {
            const first_result = first(bytes);
            var rest = first_result[1];
            const t = first_result[0];

            rest = second(rest)[1];

            const third_result = third(rest);
            const u = third_result[0];
            rest = third_result[1];

            // Broken on zig 0.13.0
            // return .{ .{ t, u }, rest };
            return .{ t, u, rest };
        }
    }.invoke;
}

fn Parser(comptime T: type) type {
    return fn ([]u8) struct { T, []u8 };
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

fn abs(a: u64, b: u64) u64 {
    return if (a > b) a - b else b - a;
}

test "take_while_digit" {
    const input = "837.152";
    const result = take_while_digit(@constCast(input));
    try std.testing.expectEqualSlices(u8, "837", result[0]);
    try std.testing.expectEqualSlices(u8, ".152", result[1]);
}
