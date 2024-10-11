const std = @import("std");

const MAX_LINE_LENGTH = 1024;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    // Create a buffer for reading lines
    var buf: [MAX_LINE_LENGTH]u8 = undefined;

    var sum: u64 = 0;

    // Read and print lines
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const value = try parse_digits(line);
        sum += value;
    }

    std.debug.print("{d}\n", .{sum});
}

fn parse_digits(line: []u8) !u8 {
    var index: u8 = 0;

    const first_digit: ?u8 = while (index < line.len) {
        const result = parse_digit(line[index..]) catch .{ null, 1 };

        if (result[0]) |digit| {
            break digit;
        }

        index += result[1];
    } else null;

    index = @intCast(line.len - 1);
    const second_digit: u8 = while (index >= 0) {
        const result = parse_digit(line[index..]) catch .{ null, 1 };

        if (result[0]) |digit| {
            break digit;
        }

        index -= result[1];
    } else first_digit;

    if (first_digit) |f| {
        return f * 10 + second_digit;
    } else {
        return ParseDigitsError.digit_not_found;
    }
}

fn parse_digit(string: []u8) !struct { u8, u8 } {
    return parse_numeric_char(string[0..1]) catch
        parse_one(string) catch
        parse_two_or_three(string) catch
        parse_four_or_five(string) catch
        parse_six_or_seven(string) catch
        parse_eight(string) catch
        parse_nine(string);
}
const ParseDigitsError = error{digit_not_found};

fn parse_numeric_char(string: []u8) !struct { u8, u8 } {
    return .{ try std.fmt.parseInt(u8, string, 10), 1 };
}

fn parse_one(string: []u8) !struct { u8, u8 } {
    if (string.len > 2) {
        if (string[0] == 'o' and string[1] == 'n' and string[2] == 'e') {
            return .{ 1, 3 };
        }
    }

    return ParseDigitsError.digit_not_found;
}

fn parse_two_or_three(string: []u8) !struct { u8, u8 } {
    if (string[0] == 't') {
        if (string.len > 2 and string[1] == 'w' and string[2] == 'o') {
            return .{ 2, 3 };
        } else if (string.len > 4 and string[1] == 'h' and string[2] == 'r' and string[3] == 'e' and string[4] == 'e') {
            return .{ 3, 4 };
        } else {
            return ParseDigitsError.digit_not_found;
        }
    } else {
        return ParseDigitsError.digit_not_found;
    }
}

fn parse_four_or_five(string: []u8) !struct { u8, u8 } {
    if (string[0] == 'f') {
        if (string.len > 3 and string[1] == 'o' and string[2] == 'u' and string[3] == 'r') {
            return .{ 4, 4 };
        } else if (string.len > 3 and string[1] == 'i' and string[2] == 'v' and string[3] == 'e') {
            return .{ 5, 4 };
        } else {
            return ParseDigitsError.digit_not_found;
        }
    } else {
        return ParseDigitsError.digit_not_found;
    }
}

fn parse_six_or_seven(string: []u8) !struct { u8, u8 } {
    if (string[0] == 's') {
        if (string.len > 2 and string[1] == 'i' and string[2] == 'x') {
            return .{ 6, 3 };
        } else if (string.len > 4 and string[1] == 'e' and string[2] == 'v' and string[3] == 'e' and string[4] == 'n') {
            return .{ 7, 5 };
        } else {
            return ParseDigitsError.digit_not_found;
        }
    } else {
        return ParseDigitsError.digit_not_found;
    }
}

fn parse_eight(string: []u8) !struct { u8, u8 } {
    if (string.len > 4 and string[0] == 'e' and string[1] == 'i' and string[2] == 'g' and string[3] == 'h' and string[4] == 't') {
        return .{ 8, 5 };
    } else {
        return ParseDigitsError.digit_not_found;
    }
}

fn parse_nine(string: []u8) !struct { u8, u8 } {
    if (string.len > 3 and string[0] == 'n' and string[1] == 'i' and string[2] == 'n' and string[3] == 'e') {
        return .{ 9, 4 };
    } else {
        return ParseDigitsError.digit_not_found;
    }
}

const expect = std.testing.expect;

test "can get two" {
    // const example = "two1";
    const example = [_]u8{ 't', 'w', 'o', '1' };
    const result = try parse_digits(@constCast(&example));
    try expect(result == 21);

    const example2 = [_]u8{ 't', 'w', 'o', '1', 't' };
    const result2 = try parse_digits(@constCast(&example2));
    try expect(result2 == 21);

    const example3 = [_]u8{ 't', 'w', 'o', 't', 'h', 'r', 'e', 'e', 't', 'e', 'e', 'n' };
    const result3 = try parse_digits(@constCast(&example3));
    try expect(result3 == 23);

    const example4 = [_]u8{ 'o', 'n', 'e', 't', 'w', 'o', 't', 'h', 'r', 'e', 'e', 't', 'e', 'e', 'n' };
    const result4 = try parse_digits(@constCast(&example4));
    try expect(result4 == 13);

    const example5 = [_]u8{ 'x', 't', 'w', 'o', 'n', 'e', '3', 't', 'w', 'o', 'n', 'e' };
    const result5 = try parse_digits(@constCast(&example5));
    try expect(result5 == 21);
}
