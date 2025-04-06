const std = @import("std");

pub const ParseError = error{
    /// The parser could succeed given more input, but ran out.
    Incomplete,
    /// An unrecoverable failure has occurred.
    Panic,
};

pub fn Parser(comptime T: type) type {
    return fn ([]u8) ParseError!struct { T, []u8 };
}

/// Match a string of one or more characters.
pub fn tag(comptime pattern: []const u8) Parser([]const u8) {
    const s = struct {
        fn invoke(rest: []u8) ParseError!struct { []const u8, []u8 } {
            if (rest.len < pattern.len) {
                return ParseError.Incomplete;
            } else {
                for (pattern, 0..) |char, j| {
                    if (rest[j] != char) {
                        return ParseError.Panic;
                    }
                } else {
                    return .{ pattern, rest[pattern.len..] };
                }
            }
        }
    };

    return s.invoke;
}

/// Look for the given character, and then discard it.
pub fn skip(comptime char: u8) Parser(void) {
    const s = struct {
        pub fn invoke(rest: []u8) ParseError!struct { void, []u8 } {
            if (rest.len < 1) {
                return ParseError.Incomplete;
            } else {
                if (rest[0] == char) {
                    return .{ {}, rest[1..] };
                } else {
                    return ParseError.Panic;
                }
            }
        }
    };

    return s.invoke;
}

/// Parse a u32 from a string, returns as i32 for ease of use
pub fn int(
    rest: []u8,
) !struct { i32, []u8 } {
    const results = try take_while_digit(rest);

    return .{ try std.fmt.parseInt(i32, results[0], 10), results[1] };
}

/// Parse any number of consecutive (base 10) digits
pub fn take_while_digit(rest: []u8) ParseError!struct { []u8, []u8 } {
    if (rest.len > 1) {
        var index: u32 = 0;
        while (index < rest.len and is_digit(rest[index])) {
            index += 1;
        }

        if (index == 0) {
            return ParseError.Panic;
        } else {
            return .{ rest[0..index], rest[index..] };
        }
    } else {
        if (rest.len == 0) {
            return ParseError.Incomplete;
        } else {
            if (is_digit(rest[0])) {
                return .{ rest[0..1], &[_]u8{} };
            } else {
                return .{ &[_]u8{}, rest };
            }
        }
    }
}

test "take_while_digit" {
    const input = "837.152";
    const result = try take_while_digit(@constCast(input));
    try std.testing.expectEqualSlices(u8, "837", result[0]);
    try std.testing.expectEqualSlices(u8, ".152", result[1]);
}

pub fn is_digit(char: u64) bool {
    return char > '/' and char < ':';
}

test "is_digit" {
    try std.testing.expectEqual('0', 48);
    try std.testing.expectEqual('9', 57);

    try std.testing.expect(is_digit('0'));
    try std.testing.expect(is_digit('1'));
    try std.testing.expect(is_digit('2'));
    try std.testing.expect(is_digit('3'));
    try std.testing.expect(is_digit('4'));
    try std.testing.expect(is_digit('5'));
    try std.testing.expect(is_digit('6'));
    try std.testing.expect(is_digit('7'));
    try std.testing.expect(is_digit('8'));
    try std.testing.expect(is_digit('9'));

    try std.testing.expect(!is_digit('a'));
}

// Discard all output until a digit is found.
fn skip_until_digit(rest: []u8) ParseError!struct { void, []u8 } { // u64 {
    var index: u32 = 0;
    while (index < rest.len) : (index += 1) {
        if (is_digit(rest[index])) {
            if (index > 0) {
                return .{ {}, rest[index..] };
            } else {
                return .Incomplete;
            }
        }
    }

    return .{ {}, &[_]u8{} };
}

/// Discard the results of the first parser, then return the results of the
/// second parser.
pub fn preceded(
    comptime T: type,
    comptime U: type,
    drop: Parser(T),
    keep: Parser(U),
) Parser(U) {
    const s = struct {
        pub fn invoke(rest: []u8) ParseError!struct { U, []u8 } {
            _, const remaining = try drop(rest);

            return keep(remaining);
        }
    };

    return s.invoke;
}

/// Return the results of the first parser, then discard the results of the
/// second parser.
pub fn terminated(
    comptime T: type,
    comptime U: type,
    keep: Parser(T),
    drop: Parser(U),
) Parser(T) {
    const s = struct {
        pub fn invoke(rest: []u8) ParseError!struct { T, []u8 } {
            const result, var remaining = try keep(rest);
            // std.debug.print("\nterminate rest: '{s}'\n", .{rest});
            // std.debug.print("\nterminate result: '{s} {s}'\n", result);
            // std.debug.print("\nterminate remaining: '{s}'\n", .{remaining});
            _, remaining = try drop(remaining);

            return .{ result, remaining };
        }
    };

    return s.invoke;
}

/// Return the results of left and right, discarding the middle.
pub fn delimited(
    comptime T: type,
    comptime U: type,
    comptime V: type,
    left: Parser(T),
    middle: Parser(U),
    right: Parser(V),
) Parser(struct { T, V }) {
    const s = struct {
        pub fn invoke(rest: []u8) ParseError!struct { struct { T, V }, []u8 } {
            var remaining: []u8 = rest;

            const left_out, remaining = try left(remaining);
            _, remaining = try middle(remaining);
            const right_out, remaining = try right(remaining);

            return .{ .{ left_out, right_out }, remaining };
        }
    };

    return s.invoke;
}

pub fn take_while_m_n(m: usize, n: usize, predicate: fn (u64) bool) Parser([]u8) {
    const s = struct {
        pub fn invoke(rest: []u8) ParseError!struct { []u8, []u8 } {
            if (rest.len < m) {
                return ParseError.Incomplete;
            } else {
                var i: usize = 0;
                const max = @min(n, rest.len);

                while (i < max and predicate(rest[i])) {
                    i += 1;
                }

                if (i >= m) {
                    return .{ rest[0..i], rest[i..] };
                } else {
                    return ParseError.Panic;
                }
            }
        }
    };

    return s.invoke;
}

// zig fmt: off
pub fn either(
    T: type,
    left: Parser(T),
    right: Parser(T)
) Parser(T) {
    // zig fmt: on
    const s = struct {
        pub fn invoke(rest: []u8) ParseError!struct { T, []u8 } {
            if (left(rest)) |result| {
                return result;
            } else |err| {
                switch (err) {
                    ParseError.Incomplete => return err,
                    ParseError.Panic => return right(rest),
                }
            }
        }
    };

    return s.invoke;
}

test "either" {
    const parse_foobar = either([]const u8, tag("foo"), tag("bar"));

    const foo, var rest = try parse_foobar(@constCast("foo"));
    try std.testing.expectEqual(rest.len, 0);
    try std.testing.expectEqual(foo, "foo");

    const bar, rest = try parse_foobar(@constCast("bar"));
    try std.testing.expectEqual(rest.len, 0);
    try std.testing.expectEqual(bar, "bar");
}
