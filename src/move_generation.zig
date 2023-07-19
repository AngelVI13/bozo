const std = @import("std");
const defs = @import("move_defs.zig");

// HorizontalAndVerticalMoves Generate a bitboard of all possible horizontal and vertical moves for a given square
pub fn horizontal_and_vertical_moves(square: u8, occupied: u64) u64 {
    // TODO: more elegant way to handle those casts
    const binarySquare: u64 = @as(u64, 1) << @intCast(u6, square);
    const fileMaskIdx = square % 8;
    const possibilitiesHorizontal = (occupied -% 2 * binarySquare) ^ @byteSwap(@byteSwap(occupied) -% 2 * @byteSwap(binarySquare));
    const possibilitiesVertical = ((occupied & defs.FileMasks8[fileMaskIdx]) -% (2 * binarySquare)) ^ @byteSwap(@byteSwap(occupied & defs.FileMasks8[fileMaskIdx]) -% (2 * @byteSwap(binarySquare)));
    return (possibilitiesHorizontal & defs.RankMasks8[square / 8]) | (possibilitiesVertical & defs.FileMasks8[fileMaskIdx]);
}

// DiagonalAndAntiDiagonalMoves Generate a bitboard of all possible diagonal and anti-diagonal moves for a given square
pub fn diagonal_and_antidiagonal_moves(square: u8, occupied: u64) u64 {
    const binarySquare: u64 = @as(u64, 1) << @intCast(u6, square);
    const diagonalMaskIdx = (square / 8) + (square % 8);
    const antiDiagonalMaskIdx = (square / 8) + 7 - (square % 8);
    const possibilitiesDiagonal = ((occupied & defs.DiagonalMasks8[diagonalMaskIdx]) -% (2 * binarySquare)) ^ @byteSwap(@byteSwap(occupied & defs.DiagonalMasks8[diagonalMaskIdx]) -% (2 * @byteSwap(binarySquare)));
    const possibilitiesAntiDiagonal = ((occupied & defs.AntiDiagonalMasks8[antiDiagonalMaskIdx]) -% (2 * binarySquare)) ^ @byteSwap(@byteSwap(occupied & defs.AntiDiagonalMasks8[antiDiagonalMaskIdx]) -% (2 * @byteSwap(binarySquare)));
    return (possibilitiesDiagonal & defs.DiagonalMasks8[diagonalMaskIdx]) | (possibilitiesAntiDiagonal & defs.AntiDiagonalMasks8[antiDiagonalMaskIdx]);
}
