const std = @import("std");
const parse = @import("./parse.zig");

// Bad
const MAX_LINE_LENGTH = 30;
// const MAX_LINE_LENGTH = 512;
// const MAX_LINE_LENGTH = 768;
// const MAX_LINE_LENGTH = 896;
// const MAX_LINE_LENGTH = 1010;

// Works
// const MAX_LINE_LENGTH = 1020;
// const MAX_LINE_LENGTH = 1024;

comptime {
    // Line length must be twice the size of the longest parser match,
    // to prevent @memcpy from crashing
    std.debug.assert(MAX_LINE_LENGTH > 2 * 12);
    // Line length shouldn't exceed that of the internal buffer.
    std.debug.assert(MAX_LINE_LENGTH <= 4096);
}

pub fn main() !void {
    const stdin_file = std.io.getStdIn();
    var buf_reader = std.io.bufferedReader(stdin_file.reader());
    var in_stream = buf_reader.reader();

    var buf: [MAX_LINE_LENGTH]u8 = undefined;

    var length: usize = 1;
    var filled: u32 = 0;
    var rest: []u8 = undefined;

    var count: u32 = 0;
    var sum: u32 = 0;
    var read_bytes: u32 = 0;

    while (length > 0) {
        // Fill buf
        // std.debug.assert(filled == 0); // untrue assertion
        while (length > 0 and filled < buf.len) {
            length = try in_stream.read(buf[filled..]);

            filled += @intCast(length);
        }
        std.debug.assert(filled <= buf.len);

        rest = buf[0..filled];
        // std.debug.print("n: '{}'\n", .{length});
        // std.debug.print("buff: '{s}'\n", .{buf});
        std.debug.print("line({}): '{s}'\n", .{ filled, buf[0..filled] });

        while (rest.len > 0) {
            // TODO: preceded(take_while(is_not('m')), parse_mul)
            if (rest[0] == 'm') {
                // std.debug.print("rest: '{s}'\n", .{rest});
                const x, rest = parse_mul(rest) catch |err| {
                    _ = switch (err) {
                        parse.ParseError.Panic => {
                            rest = rest[1..];
                        },
                        parse.ParseError.Incomplete => {
                            // std.debug.print("incomplete: {s}\n", .{rest});
                            // // std.debug.print("buf: '{any}'\n", .{buf});
                            // std.debug.print("\tbuf({}): '{s}'\n", .{ buf.len, buf });
                            // std.debug.print("\tbuf[0..rest.len]: '{s}'\n", .{buf[0..rest.len]});
                            @memcpy(buf[0..rest.len], rest);
                            filled = @intCast(rest.len);
                            break;
                        },
                    };

                    continue;
                };
                if (x[0].len < 4 and x[1].len < 4) {
                    std.debug.print("mul({s},{s})\n", .{ x[0], x[1] });
                    count += 1;
                    sum += try mul(x[0], x[1]);
                }
            } else {
                rest = rest[1..];
            }
        }

        // Reset
        if (filled == buf.len) {
            read_bytes += @intCast(filled);
            filled = 0;
        } else {
            read_bytes += @intCast(buf.len - filled);
        }
        // std.debug.print("processed {}\n", .{read_bytes});
    }

    std.debug.print("count: {}\n", .{count});
    std.debug.print("sum: {}", .{sum});
}

/// Parse mul(x, y), where x and y are unsigned integers
// zig fmt: off
const parse_mul: parse.Parser(struct { []u8, []u8 }) = parse.preceded(
    []const u8,
    struct { []u8, []u8 },
    // []u8,
    parse.tag("mul("),
    // parse.take_while_digit,
    parse.terminated(
        struct { []u8, []u8 },
        void,
        parse.delimited(
            []u8,
            void,
            []u8,
            parse.take_while_digit,
            parse.skip(','),
            parse.take_while_digit,
        ),
        parse.skip(')')
    )
);

fn mul(a: []u8, b: []u8) !u32 {
    const a_val = try std.fmt.parseInt(u32, a, 10);
    const b_val = try std.fmt.parseInt(u32, b, 10);

    return a_val * b_val;
}
