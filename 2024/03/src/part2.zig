const std = @import("std");
const parse = @import("./parse.zig");

// Bad
const MAX_LINE_LENGTH = 30;

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

    var read_bytes: u32 = 0;

    var parser: Parser = .{};

    while (length > 0) {
        // Fill buf
        while (length > 0 and filled < buf.len) {
            length = try in_stream.read(buf[filled..]);

            filled += @intCast(length);
        }
        std.debug.assert(filled <= buf.len);

        rest = buf[0..filled];
        // std.debug.print("line({}): '{s}'\n", .{ filled, buf[0..filled] });

        while (rest.len > 0) {
            if (parser.parse_bytes(rest)) |remaining| {
                rest = remaining;
            } else |err| {
                switch (err) {
                    parse.ParseError.Panic => {
                        rest = rest[1..];
                    },
                    parse.ParseError.Incomplete => {
                        @memcpy(buf[0..rest.len], rest);
                        filled = @intCast(rest.len);
                        break;
                    },
                }
            }

            // Reset
            if (filled == buf.len) {
                read_bytes += @intCast(filled);
                filled = 0;
            } else {
                read_bytes += @intCast(buf.len - filled);
            }
        }
    }

    parser.print();
}

const Parser = struct {
    disabled: bool = false,
    sum: u32 = 0,
    // count: u32 = 0,

    pub fn parse_bytes(self: *Parser, rest: []u8) parse.ParseError![]u8 {
        if (self.disabled) {
            if (parse_do(rest)) |_| {
                self.disabled = false;
                return rest[4..];
            } else |err| {
                return err;
            }
        } else {
            if (parse_dont(rest)) |_| {
                self.disabled = true;
                return rest[7..];
            } else |err| {
                switch (err) {
                    parse.ParseError.Incomplete => return err,
                    parse.ParseError.Panic => {
                        // TODO: preceded(take_while(is_not('m')), parse_mul)
                        const x, const remaining = parse_mul(rest) catch |e| {
                            return e;
                        };

                        // std.debug.print("mul({},{})\n", .{ x[0], x[1] });
                        // self.count += 1;
                        self.sum = x[0] * x[1] + self.sum;

                        return remaining;
                    },
                }
            }
        }
    }

    pub fn print(self: Parser) void {
        // std.debug.print("count: {}\n", .{self.count});
        // std.debug.print("sum: {}", .{self.sum});
        std.debug.print("{}", .{self.sum});
    }
};

const parse_do = parse.tag("do()");
const parse_dont = parse.tag("don't()");

/// Parse mul(x, y), where x and y are unsigned integers
// zig fmt: off
const parse_mul = parse.preceded(
    []const u8,
    struct { u32, u32 },
    parse.tag("mul("),
    parse.terminated(
        struct { u32, u32 },
        void,
        parse.delimited(
            u32,
            void,
            u32,
            parse_number,
            parse.skip(','),
            parse_number
        ),
        parse.skip(')')
    )
);

fn parse_number(rest: []u8) !struct { u32, []u8 } {
    const it, const remaining = try parse.take_while_m_n(1, 3, parse.is_digit)(rest);

    if (std.fmt.parseInt(u32, it, 10)) |n| {
        return .{ n, remaining };
    } else |_| {
        return parse.ParseError.Panic;
    }    
}
