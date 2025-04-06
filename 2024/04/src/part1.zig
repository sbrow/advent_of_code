pub fn main() !void {
    var file = try std.fs.cwd().openFile("example.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [11]u8 = undefined;
    var lines: [4][10]u8 = undefined;
    var line_no: u16 = 0;

    std.debug.print("{}", .{@TypeOf(in_stream)});

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        @memcpy(lines[0 .. line.len - 1], line[0 .. line.len - 1]);

        std.debug.print("{s}|\n", .{lines});
        line_no += 1;
    }
}

fn xmas_lr(rest: []u8) bool {
    return is_xmas(0, 1, 2, 3, rest);
}

test "xmas_lr" {
    try std.testing.expectEqual(true, xmas_lr(@constCast("XMAS")));
    try std.testing.expectEqual(false, xmas_lr(@constCast("XXMAS")));
    try std.testing.expectEqual(false, xmas_lr(@constCast("SAMX")));
}

fn is_xmas(x: usize, m: usize, a: usize, s: usize, rest: []u8) bool {
    return rest[x] == 'X' and rest[m] == 'M' and rest[a] == 'A' and rest[s] == 'S';
}

fn xmas_rl(rest: []u8) bool {
    return is_xmas(3, 2, 1, 0, rest);
}

test "xmas_rl" {
    try std.testing.expectEqual(false, xmas_rl(@constCast("XMAS")));
    try std.testing.expectEqual(false, xmas_rl(@constCast("XXMAS")));
    try std.testing.expectEqual(true, xmas_rl(@constCast("SAMX")));
}

fn xmas_tb(rest: []u8) bool {
    return is_xmas(3, 2, 1, 0, rest);
}

test "xmas_tb" {
    try std.testing.expectEqual(false, xmas_tb(@constCast("XMAS")));
    try std.testing.expectEqual(false, xmas_tb(@constCast("XXMAS")));
    try std.testing.expectEqual(true, xmas_tb(@constCast("SAMX")));
}

// TODO: xmas_bt
// TODO: xmas_tlbr
// TODO: xmas_brtl
// TODO: xmas_trbl
// TODO: xmas_bltr

const key = "XMAS";

const std = @import("std");
