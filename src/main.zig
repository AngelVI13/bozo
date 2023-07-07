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
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    _ = alloc;

    try hash.init_hash_keys();

    var b = board.new();
    try std.testing.expectEqual(b.positionKey, 0);

    try b.parse_fen(board.StartingPosition);
    try std.testing.expect(b.positionKey != 0);

    // std.debug.print("\n\n{s}\n", .{try b.stringify(alloc)});
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.WP));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.WN));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.WB));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.WR));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.WQ));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.WK));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.BP));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.BN));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.BB));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.BR));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.BQ));
    // try bitboard.draw(alloc, b.bitboards.get(board.BitBoardIdx.BK));
}
