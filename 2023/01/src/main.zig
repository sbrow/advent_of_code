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

    // Read and print lines
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |_| {
        // std.debug.print("{s}", .{line});
        const x = try parse_digits(buf);
        // std.debug.print(", {c},{c}", .{ x[0], x[1] });

        const value = try std.fmt.parseInt(u8, &x, 10);
        // std.debug.print(", ({any})", .{value});

        //std.debug.print("\n", .{});
        sum += value;
    }

    std.debug.print("{d}\n", .{sum});
}

const ParseDigitsError = error{DigitNotFound};
fn parse_digits(line: [MAX_LINE_LENGTH]u8) ![2]u8 {
    var first_digit: ?u8 = null;
    var second_digit: u8 = undefined;

    for (line) |char| {
        if (is_digit(char)) {
            second_digit = char;

            if (first_digit == null) {
                first_digit = char;
            }
        } else if (char == '\n') {
            if (first_digit) |f| {
                return .{ f, second_digit };
            } else {
                return ParseDigitsError.DigitNotFound;
            }
        }
    }

    return ParseDigitsError.DigitNotFound;
}

fn is_digit(char: u64) bool {
    return char > 47 and char < 58;
}

const expect = std.testing.expect;

test "numbers are digits" {
    for ('0'..'9') |n| {
        try expect(is_digit(n));
    }
}

test "letters are not digits" {
    for ('a'..'z') |char| {
        try expect(is_digit(char) == false);
    }

    for ('A'..'Z') |char| {
        try expect(is_digit(char) == false);
    }
}

test "can check undefined" {
    var first_digit: u8 = undefined;
    var second_digit: u8 = undefined;

    second_digit = 12;

    try expect(second_digit != undefined);
    try expect(first_digit != undefined);

    first_digit = second_digit;
}
