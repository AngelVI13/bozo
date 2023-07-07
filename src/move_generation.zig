const std = @import("std");

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

// HorizontalAndVerticalMoves Generate a bitboard of all possible horizontal and vertical moves for a given square
pub fn horizontal_and_vertical_moves(square: u8, occupied: u64) u64 {
    const binarySquare: u64 = 1 << square;
    const fileMaskIdx = square % 8;
    const possibilitiesHorizontal = (occupied - 2 * binarySquare) ^ @byteSwap(@byteSwap(occupied) - 2 * @byteSwap(binarySquare));
    const possibilitiesVertical = ((occupied & FileMasks8[fileMaskIdx]) - (2 * binarySquare)) ^ @byteSwap(@byteSwap(occupied & FileMasks8[fileMaskIdx]) - (2 * @byteSwap(binarySquare)));
    return (possibilitiesHorizontal & RankMasks8[square / 8]) | (possibilitiesVertical & FileMasks8[fileMaskIdx]);
}

// DiagonalAndAntiDiagonalMoves Generate a bitboard of all possible diagonal and anti-diagonal moves for a given square
pub fn diagonal_and_antidiagonal_moves(square: u8, occupied: u64) u64 {
    const binarySquare: u64 = 1 << square;
    const diagonalMaskIdx = (square / 8) + (square % 8);
    const antiDiagonalMaskIdx = (square / 8) + 7 - (square % 8);
    const possibilitiesDiagonal = ((occupied & DiagonalMasks8[diagonalMaskIdx]) - (2 * binarySquare)) ^ @byteSwap(@byteSwap(occupied & DiagonalMasks8[diagonalMaskIdx]) - (2 * @byteSwap(binarySquare)));
    const possibilitiesAntiDiagonal = ((occupied & AntiDiagonalMasks8[antiDiagonalMaskIdx]) - (2 * binarySquare)) ^ @byteSwap(@byteSwap(occupied & AntiDiagonalMasks8[antiDiagonalMaskIdx]) - (2 * @byteSwap(binarySquare)));
    return (possibilitiesDiagonal & DiagonalMasks8[diagonalMaskIdx]) | (possibilitiesAntiDiagonal & AntiDiagonalMasks8[antiDiagonalMaskIdx]);
}
