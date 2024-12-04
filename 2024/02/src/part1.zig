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
    const results = delimited(
        take_while_digit,
        skip_until_digit,
        take_while_digit,
    )(report);

    // const results = take_while_digit(report);
    // const first = results[0];
    // const rest = skip_until_digit(results[1]);

    // const second_results = take_while_digit(rest);
    // const second = second_results[0];

    std.debug.print("({s}, {s})...{s}\n", .{ results[0][1], results[0][2], results[1] });

    return true;
}

fn delimited(comptime first: Parser, comptime second: Parser, comptime third: Parser) Parser {
    const result = struct {
        fn invoke(bytes: []u8) struct { [2][]u8, []u8 } {
            const results = first(bytes);
            const first_result = results[0];
            const rest = second(results[1]);

            const second_results = third(rest);
            const second_result = second_results[0];
            const the_rest = second_results[1];

            return [2][]u8{ .{ first_result, second_result }, the_rest };
        }
    };

    return result.invoke;
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
