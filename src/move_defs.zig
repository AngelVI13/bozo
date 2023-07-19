const std = @import("std");
const board = @import("board.zig");
const Allocator = std.mem.Allocator;
const BB = board.BitBoardIdx;

// The following bitmasks represent squares starting from H1-A1 -> H8-A8. Ranks are separated by "_"

// FileA Bitmask for selecting all squares that are on the A file
pub const FileA: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_00000001;

// FileH Bitmask for selecting all squares that are on the H file
pub const FileH: u64 = 0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000;

// FileAB Bitmask for selecting all squares that are on the A & B files
pub const FileAB: u64 = 0b00000011_00000011_00000011_00000011_00000011_00000011_00000011_00000011;

// FileGH Bitmask for selecting all squares that are on the G & H files
pub const FileGH: u64 = 0b11000000_11000000_11000000_11000000_11000000_11000000_11000000_11000000;

// Rank8 Bitmask for selecting all squares that are on the 8th rank
pub const Rank8: u64 = 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_11111111;

// Rank5 Bitmask for selecting all squares that are on the 5th rank
pub const Rank5: u64 = 0b00000000_00000000_00000000_00000000_11111111_00000000_00000000_00000000;

// Rank4 Bitmask for selecting all squares that are on the 4th rank
pub const Rank4: u64 = 0b00000000_00000000_00000000_11111111_00000000_00000000_00000000_00000000;

// Rank1 Bitmask for selecting all squares that are on the 1st rank
pub const Rank1: u64 = 0b11111111_00000000_00000000_00000000_00000000_00000000_00000000_00000000;

// Center Bitmask for selecting all center squares (D4, E4, D5, E5)
pub const Center: u64 = 0b00000000_00000000_00000000_00011000_00011000_00000000_00000000_00000000;

// ExtendedCenter Bitmask for selecting all extended center squares (C3 - F3, C4 - F4, C5 - F5)
pub const ExtendedCenter: u64 = 0b00000000_00000000_00111100_00111100_00111100_00111100_00000000_00000000;

// QueenSide Bitmask for selecting all queenside squares
pub const QueenSide: u64 = 0b00001111_00001111_00001111_00001111_00001111_00001111_00001111_00001111;

// KingSide Bitmask for selecting all kingside squares
pub const KingSide: u64 = 0b11110000_11110000_11110000_11110000_11110000_11110000_11110000_11110000;

// KnightSpan Bitmask for selecting all knight moves
pub const KnightSpan: u64 = 43234889994;

// KingSpan Bitmask for selecting all king moves
pub const KingSpan: u64 = 460039;

// FileMasks8 Array that holds bitmasks that select a given file based on the index of
// the element i.e. index 0 selects File A, 1- FileB etc.
pub const FileMasks8 = [8]u64{
    0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_00000001,
    0b00000010_00000010_00000010_00000010_00000010_00000010_00000010_00000010,
    0b00000100_00000100_00000100_00000100_00000100_00000100_00000100_00000100,
    0b00001000_00001000_00001000_00001000_00001000_00001000_00001000_00001000,
    0b00010000_00010000_00010000_00010000_00010000_00010000_00010000_00010000,
    0b00100000_00100000_00100000_00100000_00100000_00100000_00100000_00100000,
    0b01000000_01000000_01000000_01000000_01000000_01000000_01000000_01000000,
    0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000,
};

// RankMasks8 Array that holds bitmasks that select a given rank based on the index of
// the element i.e. index 0 selects Rank 1, 2- Rank 2 etc.
// seems like index 0 is equal to rank8 from above
pub const RankMasks8 = [8]u64{
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_11111111,
    0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000,
    0b00000000_00000000_00000000_00000000_00000000_11111111_00000000_00000000,
    0b00000000_00000000_00000000_00000000_11111111_00000000_00000000_00000000,
    0b00000000_00000000_00000000_11111111_00000000_00000000_00000000_00000000,
    0b00000000_00000000_11111111_00000000_00000000_00000000_00000000_00000000,
    0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000,
    0b11111111_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
};

// DiagonalMasks8 Bitmask to help select all diagonals
pub const DiagonalMasks8 = [15]u64{
    0x1,                0x102,             0x10204,           0x1020408,         0x102040810,        0x10204081020,      0x1020408102040,
    0x102040810204080,  0x204081020408000, 0x408102040800000, 0x810204080000000, 0x1020408000000000, 0x2040800000000000, 0x4080000000000000,
    0x8000000000000000,
};

// AntiDiagonalMasks8 Bitmask to help select all anti diagonal
pub const AntiDiagonalMasks8 = [15]u64{
    0x80,               0x8040,             0x804020,           0x80402010,         0x8040201008,      0x804020100804,    0x80402010080402,
    0x8040201008040201, 0x4020100804020100, 0x2010080402010000, 0x1008040201000000, 0x804020100000000, 0x402010000000000, 0x201000000000000,
    0x100000000000000,
};

// CastleRooks Array containing all initial rook squares
pub const CastleRooks = [4]u8{ 63, 56, 7, 0 };

pub const H1 = 63;
pub const A1 = 56;
pub const A8 = 0;
pub const H8 = 7;
pub const D1 = 59;
pub const F1 = 61;
pub const D8 = 3;
pub const F8 = 5;
pub const G1 = 62;
pub const C1 = 58;
pub const C8 = 2;
pub const G8 = 6;
pub const E1 = 60;
pub const E8 = 4;

// Game move - information stored in the move int from type Move
//               |Ca| |--To-||-From-|
// 0000 0000 0000 0000 0000 0011 1111 -> From - 0x3F
// 0000 0000 0000 0000 1111 1100 0000 -> To - >> 6, 0x3F
// 0000 0000 0000 1111 0000 0000 0000 -> Captured Piece Type - >> 12, 0xF
// 0000 0000 0001 0000 0000 0000 0000 -> En passant capt - >> 16 - 0x40000
// 0000 0000 0010 0000 0000 0000 0000 -> PawnStart - >> 17 - 0x80000
// 0000 0011 1100 0000 0000 0000 0000 -> Promotion to what piece - >> 18, 0xF
// 0000 0100 0000 0000 0000 0000 0000 -> Castle - >> 22 0x1000000

// FromSq - macro that returns the 'from' bits from the move int
pub fn FromSq(m: u32) u32 {
    return m & 0x3f;
}

// ToSq - macro that returns the 'to' bits from the move int
pub fn ToSq(m: u32) u32 {
    return (m >> 6) & 0x3f;
}

// Captured - macro that returns the 'Captured' bits from the move int
pub fn Captured(m: u32) u32 {
    return (m >> 12) & 0xf;
}

// Promoted - macro that returns the 'Promoted' bits from the move int
pub fn Promoted(m: u32) u32 {
    return (m >> 18) & 0xf;
}

// PawnStartFlag - macro that returns the 'PawnStart' flag bits from the move int
pub fn PawnStartFlag(m: u32) u32 {
    return (m >> 17) & 1;
}

// EnPassantFlag - macro that returns the 'EnPassant' capture flag bits from the move int
pub fn EnPassantFlag(m: u32) u32 {
    return (m >> 16) & 1;
}

// CastleFlag - macro that returns the 'CastleFlag' flag bits from the move int
pub fn CastleFlag(m: u32) u32 {
    return (m >> 22) & 1;
}

// GetMoveInt creates and returns a move int from given move information
pub fn GetMoveInt(fromSq: u32, toSq: u32, capturedPiece: u32, promotionPiece: u32, flag: u32) u32 {
    return fromSq | (toSq << 6) | (capturedPiece << 12) | (promotionPiece << 18) | flag;
}

// MoveFlagEnPass move flag that denotes if the capture was an enpass
pub const MoveFlagEnPass = 0x10000;

// MoveFlagPawnStart move flag that denotes if move was pawn start (2x)
pub const MoveFlagPawnStart = 0x20000;

// NoFlag constant that denotes no flag is applied to move
pub const NoFlag = 0;

// MoveFlagCastle move flag that denotes if move was castling
pub const MoveFlagCastle = 0x400000;

// MaxPositionMoves maximum number of possible moves for a given position
pub const MaxPositionMoves = 256;

// MoveList Struct to hold all generated moves for a given position
pub const MoveList = struct {
    Moves: [MaxPositionMoves]u32,
    Count: u8, // number of moves on the moves list

    // AddMove Adds move to move list and updates count
    pub fn AddMove(self: *MoveList, move: u32) void {
        self.Moves[self.Count] = move;
        self.Count += 1;
    }
};

// PinRays Struct to hold all generated pin rays for a given position
pub const PinRays = struct {
    Rays: [8]u64, // an array with max possible pinned rays
    Count: u8, // number of generated pin rays in the struct

    // AddRay Adds ray to pin rays and updates count
    pub fn AddRay(self: *PinRays, ray: u64) void {
        self.Rays[self.Count] = ray;
        self.Count += 1;
    }

    // GetRay Get pin ray which corresponds to a given piece. If the given piece is not
    // pinned -> return ^0 i.e. the piece can move to any square and is not limmited by a pin ray
    pub fn GetRay(self: PinRays, pieceBitboard: u64) u64 {
        for (0..self.Count) |i| {
            if (self.Rays[i] & pieceBitboard != 0) {
                return self.Rays[i];
            }
        }
        return ~0;
    }
};

// GetSquareString get algebraic notation of square i.e. b2, a6 from array index
fn GetSquareString(alloc: Allocator, sq: u8) ![]const u8 {
    const file = sq % 8;
    const rank = 8 - (sq / 8) - 1;

    const square = try std.fmt.allocPrint(alloc, "{c}{c}", .{ 'a' + file, '1' + rank });
    return square;
}

test "GetSquareString" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var square = try GetSquareString(alloc, H1);
    try std.testing.expect(std.mem.eql(u8, square, "h1"));

    square = try GetSquareString(alloc, F1);
    try std.testing.expect(std.mem.eql(u8, square, "f1"));

    square = try GetSquareString(alloc, G1);
    try std.testing.expect(std.mem.eql(u8, square, "g1"));

    square = try GetSquareString(alloc, D8);
    try std.testing.expect(std.mem.eql(u8, square, "d8"));
}

// GetMoveString prints move in algebraic notation
fn GetMoveString(alloc: Allocator, move: u32) ![]const u8 {
    // std.debug.print("FromSq: %d, ToSq: %d, Promoted: %d\n", .{FromSq(move), ToSq(move), Promoted(move)});

    const fromSq = try GetSquareString(alloc, FromSq(move));
    const toSq = try GetSquareString(alloc, ToSq(move));

    var moveStr = try std.fmt.allocPrint(alloc, "{s}{s}", .{ fromSq, toSq });

    // if this move is a promotion, add char of the piece we promote to at the end of the move string
    // i.e. if a7a8q -> we promote to Queen
    const promoted = Promoted(move);
    const pieceChar = switch (promoted) {
        BB.WN, BB.BN => 'n',
        BB.WB, BB.BB => 'b',
        BB.WR, BB.BR => 'r',
        BB.WQ, BB.BQ => 'q',
        else => unreachable(),
    };

    moveStr = try std.fmt.allocPrint(alloc, "{s}{c}", .{ move, pieceChar });

    return move;
}

// PrintMoveList prints move list
pub fn PrintMoveList(alloc: Allocator, moveList: *MoveList) !void {
    _ = alloc;
	std.debug.print("MoveList: %d\n", .{moveList.Count});

	for (0..moveList.Count) |index| {
		const move = moveList.Moves[index];
		std.debug.print("Move:%d > %s\n", .{index+1, try GetMoveString(move)});
	}
	std.debug.print("MoveList Total: %d\n", .{moveList.Count});
}

pub fn GetMoveFromString(alloc: Allocator, moveList: *MoveList, moveString: []const u8) !u32 {
	for (0..moveList.Count) |index| {
		const move = moveList.Moves[index];
        const m = try GetMoveString(alloc, move);

		if (std.mem.eql(m, moveString)) {
			return move;
		}
	}

	return board.Errors.MoveNotFound;
}

