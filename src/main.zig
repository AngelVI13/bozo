const std = @import("std");
const board = @import("board.zig");
const hash = @import("hashkey.zig");
const bitboard = @import("bitboard.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    try hash.init_hash_keys();

    const b = board.new();
    std.debug.print("\n{s}\n", .{try b.stringify(alloc)});
}

test "parse_fen starting position" {
    try hash.init_hash_keys();

    var b = board.new();
    try std.testing.expectEqual(b.positionKey, 0);

    try b.parse_fen(board.StartingPosition);
    try std.testing.expect(b.positionKey != 0);
    try std.testing.expectEqual(b.Side, board.Color.White);
    try std.testing.expectEqual(b.ply, 0);
    try std.testing.expectEqual(b.fiftyMove, 0);
    try std.testing.expect(b.castlePermissions & board.WhiteKingCastling != 0);
    try std.testing.expect(b.castlePermissions & board.WhiteQueenCastling != 0);
    try std.testing.expect(b.castlePermissions & board.BlackKingCastling != 0);
    try std.testing.expect(b.castlePermissions & board.BlackQueenCastling != 0);
}

test "parse_fen black to move" {
    try hash.init_hash_keys();

    var b = board.new();
    try std.testing.expectEqual(b.positionKey, 0);

    try b.parse_fen("r2qkbnr/ppp1p1pp/B1n1b3/3pPp2/8/5N2/PPPP1PPP/RNBQ1RK1 b kq - 5 5");
    try std.testing.expect(b.positionKey != 0);
    try std.testing.expectEqual(b.Side, board.Color.Black);
    try std.testing.expectEqual(b.ply, 0);
    try std.testing.expectEqual(b.fiftyMove, 0);
    try std.testing.expect(b.castlePermissions & board.WhiteKingCastling == 0);
    try std.testing.expect(b.castlePermissions & board.WhiteQueenCastling == 0);
    try std.testing.expect(b.castlePermissions & board.BlackKingCastling != 0);
    try std.testing.expect(b.castlePermissions & board.BlackQueenCastling != 0);
}
