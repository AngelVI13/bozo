const std = @import("std");
const Allocator = std.mem.Allocator;

// DrawBitboard Prints a given bitboard to stdout in a human readable way
pub fn draw(alloc: Allocator, bitboard: u64) !void {
    var bitboardStr: [8][8][]const u8 = undefined;

    for (0..64) |i| {
        if (((bitboard >> @intCast(u6, i)) & 1) == 1) {
            bitboardStr[i / 8][i % 8] = "X";
        } else {
            bitboardStr[i / 8][i % 8] = ".";
        }
    }

    const boardStr = try format_board(alloc, bitboardStr);
    std.debug.print("{s}\n", .{boardStr});
}

pub fn format_board(alloc: Allocator, boardMatrix: [8][8][]const u8) ![]const u8 {
    var positionStr: []const u8 = "\n";
    for (boardMatrix, 0..boardMatrix.len) |rank, idx| {
        {
            positionStr = try std.fmt.allocPrint(alloc, "{s} {d} ", .{ positionStr, 8 - idx });
        }
        for (rank) |file| {
            {
                positionStr = try std.fmt.allocPrint(alloc, "{s} {s} ", .{ positionStr, file });
            }
        }
        positionStr = try std.fmt.allocPrint(alloc, "{s}\n", .{positionStr});
    }

    positionStr = try std.fmt.allocPrint(alloc, "{s}\n    ", .{positionStr});
    const startFileIdx: u8 = 'A';
    inline for (startFileIdx..startFileIdx + 8) |i| {
        positionStr = try std.fmt.allocPrint(alloc, "{s}{c}  ", .{ positionStr, @as(u8, i) });
    }
    positionStr = try std.fmt.allocPrint(alloc, "{s}\n", .{positionStr});
    return positionStr;
}
