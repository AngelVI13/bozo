const std = @import("std");
const board = @import("board.zig");
const move_gen = @import("move_generation.zig");

// InitHashKeys initializes hashkeys for all pieces and possible positions, for castling rights, for side to move
pub fn init_hash_keys() !void {
    // NOTE: can also just use `const rand = std.crypto.random;`
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    for (0..@enumToInt(board.BitBoardIdx.MAX)) |i| {
        for (0..board.BoardSquareNum) |j| {
            board.PieceKeys[i][j] = rand.int(u64);
        }
    }

    board.SideKey = rand.int(u64);

    for (0..board.CastleKeysNum) |i| {
        board.CastleKeys[i] = rand.int(u64);
    }

    // Pregeneration of possible knight moves
    for (0..board.BoardSquareNum) |i| {
        var possibility: u64 = 0;
        if (i > 18) {
            possibility = move_gen.KnightSpan << @intCast(u6, (i - 18));
        } else {
            possibility = move_gen.KnightSpan >> @intCast(u6, (18 - i));
        }
        if (i % 8 < 4) {
            possibility &= (~move_gen.FileGH);
        } else {
            possibility &= (~move_gen.FileAB);
        }
        board.KnightMoves[i] = possibility;
    }

    // Pregeneration of possible king moves
    for (0..board.BoardSquareNum) |i| {
        var possibility: u64 = 0;

        if (i > 9) {
            possibility = move_gen.KingSpan << @intCast(u6, (i - 9));
        } else {
            possibility = move_gen.KingSpan >> @intCast(u6, (9 - i));
        }

        if (i % 8 < 4) {
            possibility &= (~move_gen.FileGH);
        } else {
            possibility &= (~move_gen.FileAB);
        }

        board.KingMoves[i] = possibility;
    }
}
