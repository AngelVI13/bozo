const std = @import("std");
const defs = @import("move_defs.zig");
const board = @import("board.zig");
const StateBoards = board.StateBoards;
const BitBoards = board.BitBoards;

// HorizontalAndVerticalMoves Generate a bitboard of all possible horizontal and vertical moves for a given square
pub fn horizontal_and_vertical_moves(square: u8, occupied: u64) u64 {
    // TODO: more elegant way to handle those casts
    const binarySquare: u64 = @as(u64, 1) << @intCast(u6, square);
    const fileMaskIdx = square % 8;
    const possibilitiesHorizontal = (occupied -% 2 *% binarySquare) ^ @byteSwap(@byteSwap(occupied) -% 2 *% @byteSwap(binarySquare));
    const possibilitiesVertical = ((occupied & defs.FileMasks8[fileMaskIdx]) -% (2 *% binarySquare)) ^ @byteSwap(@byteSwap(occupied & defs.FileMasks8[fileMaskIdx]) -% (2 *% @byteSwap(binarySquare)));
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

pub fn unsafeForBlack(bitboards: *BitBoards, stateBoards: *StateBoards) u64 {
    var unsafe: u64 = 0;
    // pawn
    unsafe = ((bitboards.get(.WP) >> 7) & (~defs.FileA)); // pawn capture right
    unsafe |= ((bitboards.get(.WP) >> 9) & (~defs.FileH)); // pawn capture left

    var possibility: u64 = 0;
    // knight
    var wn = bitboards.get(.WN);
    var i = wn & (~(wn - 1));
    while (i != 0) {
        const iLocation = @ctz(i);
        possibility = board.KnightMoves[iLocation];
        unsafe |= possibility;
        wn &= (~i);
        i = wn & (~(wn -% 1));
    }

    // sliding pieces
    const occupiedExludingKing = stateBoards.get(.Occupied) ^ bitboards.get(.BK);
    // bishop/queen
    var qb = bitboards.get(.WQ) | bitboards.get(.WB);
    i = qb & (~(qb - 1));
    while (i != 0) {
        const iLocation = @ctz(i);
        possibility = diagonal_and_antidiagonal_moves(iLocation, occupiedExludingKing);
        unsafe |= possibility;
        qb &= (~i);
        i = qb & (~(qb -% 1));
    }

    // rook/queen
    var qr = bitboards.get(.WQ) | bitboards.get(.WR);
    i = qr & (~(qr - 1));
    while (i != 0) {
        const iLocation = @ctz(i);
        possibility = horizontal_and_vertical_moves(iLocation, occupiedExludingKing);
        unsafe |= possibility;
        qr &= (~i);
        i = qr & (~(qr -% 1));
    }

    // king
    const iLocation = @ctz(bitboards.get(.WK));
    possibility = board.KingMoves[iLocation];
    unsafe |= possibility;
    return unsafe;
}

pub fn unsafeForWhite(bitboards: *BitBoards, stateBoards: *StateBoards) u64 {
    // pawn
    var unsafe: u64 = ((bitboards.get(.BP) << 7) & (~defs.FileH)); // pawn capture right
    unsafe |= ((bitboards.get(.BP) << 9) & (~defs.FileA)); // pawn capture left

    var possibility: u64 = 0;
    // knight
    var bn = bitboards.get(.BN);
    var i = bn & (~(bn - 1));
    while (i != 0) {
        const iLocation = @ctz(i);
        possibility = board.KnightMoves[iLocation];
        unsafe |= possibility;
        bn &= (~i);
        i = bn & (~(bn -% 1));
    }

    // sliding pieces
    // when calculating unsafe squares for a given colour we need to exclude the
    // current side's king because if an enemy queen is attacking our king,
    // the squares behind the king are also unsafe, however, when the king is included
    // geneation of unsafe squares will stop at the king and will not extend behind it
    const occupiedExludingKing = stateBoards.get(.Occupied) ^ bitboards.get(.WK);
    // bishop/queen
    var qb = bitboards.get(.BQ) | bitboards.get(.BB);
    i = qb & (~(qb -% 1));
    while (i != 0) {
        const iLocation = @ctz(i);
        possibility = diagonal_and_antidiagonal_moves(iLocation, occupiedExludingKing);
        unsafe |= possibility;
        qb &= (~i);
        i = qb & (~(qb -% 1));
    }

    // rook/queen
    var qr = bitboards.get(.BQ) | bitboards.get(.BR);
    i = qr & (~(qr - 1));
    while (i != 0) {
        const iLocation = @ctz(i);
        possibility = horizontal_and_vertical_moves(iLocation, occupiedExludingKing);
        unsafe |= possibility;
        qr &= (~i);
        i = qr & (~(qr -% 1));
    }

    // king
    const iLocation = @ctz(bitboards.get(.BK));
    possibility = board.KingMoves[iLocation];
    unsafe |= possibility;
    return unsafe;
}
