const std = @import("std");

/// Match a pattern of one or more characters.
pub fn tag(comptime pattern: []const u8, rest: []u8) struct { ?[]const u8, []u8 } {
    var index: u32 = 0;

    while (index < rest.len and rest.len >= pattern.len) : (index += 1) {
        for (pattern, 0..) |char, j| {
            if (rest[index + j] != char) {
                break;
            }
        }

        return .{ pattern, rest[index + pattern.len ..] };
    } else {
        return .{ null, rest };
    }
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
