const std = @import("std");
const board = @import("board.zig");

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
			board.PieceKeys[i][j] = rand.int(u64); // returns a random 64 bit number
		}
	}

	board.SideKey = rand.int(u64);

	for (0..board.CastleKeysNum) |i|{
		board.CastleKeys[i] = rand.int(u64);
	}

    // TODO: Finish this
	// // Pregeneration of possible knight moves
	// for i := 0; i < BoardSquareNum; i++ {
	// 	var possibility uint64
	// 	if i > 18 {
	// 		possibility = KnightSpan << (i - 18)
	// 	} else {
	// 		possibility = KnightSpan >> (18 - i)
	// 	}
	// 	if i%8 < 4 {
	// 		possibility &= (^FileGH)
	// 	} else {
	// 		possibility &= (^FileAB)
	// 	}
	// 	KnightMoves[i] = possibility
	// }

	// // Pregeneration of possible king moves
	// for i := 0; i < BoardSquareNum; i++ {
	// 	var possibility uint64

	// 	if i > 9 {
	// 		possibility = KingSpan << (i - 9)
	// 	} else {
	// 		possibility = KingSpan >> (9 - i)
	// 	}

	// 	if i%8 < 4 {
	// 		possibility &= (^FileGH)
	// 	} else {
	// 		possibility &= (^FileAB)
	// 	}

	// 	KingMoves[i] = possibility
	// }
}

