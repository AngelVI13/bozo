const std = @import("std");
const bitboard = @import("bitboard.zig");
const Allocator = std.mem.Allocator;

const Errors = error{
    FenError,
    UnknownSideToMove,
    FileOutOfBounds,
};

// StartingPosition 8x8 representation of normal chess starting position
pub const StartingPosition: []const u8 = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

const SideChar: []const u8 = "wb-";
const PieceChar: []const u8 = ".PNBRQKpnbrqk";

// Indexes to access bitboards i.e. WP - white pawn, BB - black bishop
pub const BitBoardIdx = enum(u8) {
    NoPiece,
    WP,
    WN,
    WB,
    WR,
    WQ,
    WK,
    BP,
    BN,
    BB,
    BR,
    BQ,
    BK,
    EP, // en passant file bitboard
    MAX,
};

// PieceNotationMap maps piece notations (i.e. 'p', 'N') to piece values (i.e. 'BlackPawn', 'WhiteKnight')
pub const PieceNotationMap = std.ComptimeStringMap(BitBoardIdx, .{
    .{ "p", .BP },
    .{ "r", .BR },
    .{ "n", .BN },
    .{ "b", .BB },
    .{ "k", .BK },
    .{ "q", .BQ },
    .{ "P", .WP },
    .{ "R", .WR },
    .{ "N", .WN },
    .{ "B", .WB },
    .{ "K", .WK },
    .{ "Q", .WQ },
});

// IsSlider maps piece type to information if it is a sliding piece or not (i.e. rook, bishop, queen)
var IsSlider = [_]bool{
    false, // NoPiece,
    false, // WP,
    false, // WN,
    true, // WB,
    true, // WR,
    true, // WQ,
    false, // WK,
    false, // BP,
    false, // BN,
    true, // BB,
    true, // BR,
    true, // BQ,
    false, // BK,
    false, // EP,
};

const StateBoardIdx = enum(u8) {
    // NotMyPieces index to bitboard with all enemy and empty squares
    NotMyPieces,

    // MyPieces index to bitboard with all my pieces excluding my king
    MyPieces,

    // EnemyPieces index to bitboard with all the squares of enemy pieces
    EnemyPieces,

    // EnemyRooksQueens index to bitboard with all the squares of enemy rooks & queens
    EnemyRooksQueens,

    // EnemyBishopsQueens index to bitboard with all the squares of enemy bishops & queens
    EnemyBishopsQueens,

    // EnemyKnights index to bitboard with all the squares of enemy knights
    EnemyKnights,

    // EnemyPawns index to bitboard with all the squares of enemy pawns
    EnemyPawns,

    // Empty index to bitboard with all the empty squares
    Empty,

    // Occupied index to bitboard with all the occupied squares
    Occupied,

    // Unsafe index to bitboard with all the unsafe squares for the current side
    Unsafe,

    MAX,
};

// Defines for colours
pub const Color = enum(u8) {
    White,
    Black,
    Both,
};

// MaxGameMoves Maximum number of game moves
const MaxGameMoves: u16 = 2048;
pub const BoardSquareNum: u8 = 64;

// CastlePerm used to simplify hashing castle permissions
// Everytime we make a move we will take pos.castlePerm &= CastlePerm[sq]
// in this way if any of the rooks or the king moves, the castle permission will be
// disabled for that side. In any other move, the castle permissions will remain the
// same, since 15 is the max number associated with all possible castling permissions
// for both sides
const CastlePerm = [BoardSquareNum]u8{
    7,  15, 15, 15, 3,  15, 15, 11,
    15, 15, 15, 15, 15, 15, 15, 15,
    15, 15, 15, 15, 15, 15, 15, 15,
    15, 15, 15, 15, 15, 15, 15, 15,
    15, 15, 15, 15, 15, 15, 15, 15,
    15, 15, 15, 15, 15, 15, 15, 15,
    15, 15, 15, 15, 15, 15, 15, 15,
    13, 15, 15, 15, 12, 15, 15, 14,
};

// Defines for castling rights
// The values are such that they each represent a bit from a 4 bit int value
// for example if white can castle kingside and black can castle queenside
// the 4 bit int value is going to be 1001
pub const WhiteKingCastling: u8 = 1;
pub const WhiteQueenCastling: u8 = 2;
pub const BlackKingCastling: u8 = 4;
pub const BlackQueenCastling: u8 = 8;

// PieceKeys hashkeys for each piece for each possible position for the key
pub var PieceKeys: [@enumToInt(BitBoardIdx.MAX)][BoardSquareNum]u64 = undefined;

// SideKey the hashkey associated with the current side
pub var SideKey: u64 = undefined;

pub const CastleKeysNum = WhiteKingCastling + WhiteQueenCastling + BlackKingCastling + BlackQueenCastling + 1;

// CastleKeys haskeys associated with castling rights
pub var CastleKeys: [CastleKeysNum]u64 = undefined; // castling value ranges from 0-15 -> we need 16 hashkeys

// FileMasks8 Array that holds bitmasks that select a given file based on the index of
// the element i.e. index 0 selects File A, 1- FileB etc.
pub var FileMasks8 = [8]u64{
    0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_00000001,
    0b00000010_00000010_00000010_00000010_00000010_00000010_00000010_00000010,
    0b00000100_00000100_00000100_00000100_00000100_00000100_00000100_00000100,
    0b00001000_00001000_00001000_00001000_00001000_00001000_00001000_00001000,
    0b00010000_00010000_00010000_00010000_00010000_00010000_00010000_00010000,
    0b00100000_00100000_00100000_00100000_00100000_00100000_00100000_00100000,
    0b01000000_01000000_01000000_01000000_01000000_01000000_01000000_01000000,
    0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000,
};

// Undo struct
const Undo = struct {
    move: u32,
    castlePermissions: u8,
    enPassantFile: u64,
    fiftyMove: u8,
    positionKey: u64,
};

// Board Struct to represent the chess board
const Board = struct {
    position: [BoardSquareNum]BitBoardIdx, // var to keep track of all pieces on the board
    bitboards: std.EnumArray(BitBoardIdx, u64), // 0- empty, 1-12 pieces WP-BK, 13 - en passant
    stateBoards: std.EnumArray(StateBoardIdx, u64), // bitboards representing a state i.e. EnemyPieces, Empty, Occupied etc.
    Side: Color,
    castlePermissions: u8,
    ply: u16, // how many half moves have been made
    fiftyMove: u8, // how many moves from the fifty move rule have been made
    positionKey: u64, // position key is a unique key stored for each position (used to keep track of 3fold repetition)
    history: [MaxGameMoves]Undo, // array that stores current position and variables before a move is made

    // Reset Resets current board
    pub fn reset(self: *Board) void {
        var bbIterator = self.bitboards.iterator();
        while (bbIterator.next()) |e| {
            e.value.* = 0;
        }
        inline for (0..BoardSquareNum) |i| {
            self.position[i] = .NoPiece;
        }
        var sbIterator = self.stateBoards.iterator();
        while (sbIterator.next()) |e| {
            e.value.* = 0;
        }

        self.Side = Color.White;
        self.castlePermissions = 0;
        self.ply = 0;
        self.fiftyMove = 0;
        self.positionKey = 0;
    }

    // Return string representing the current board (from the stored bitboards)
    pub fn stringify(self: Board, alloc: Allocator) ![]const u8 {
        var position: [8][8][]const u8 = undefined;

        for (0..64) |i| {
            position[i / 8][i % 8] = switch (self.position[i]) {
                BitBoardIdx.WP => "P",
                BitBoardIdx.WN => "N",
                BitBoardIdx.WB => "B",
                BitBoardIdx.WR => "R",
                BitBoardIdx.WQ => "Q",
                BitBoardIdx.WK => "K",
                BitBoardIdx.BP => "p",
                BitBoardIdx.BN => "n",
                BitBoardIdx.BB => "b",
                BitBoardIdx.BR => "r",
                BitBoardIdx.BQ => "q",
                BitBoardIdx.BK => "k",
                else => ".",
            };
        }

        var positionStr = try bitboard.format_board(alloc, position);

        positionStr = try std.fmt.allocPrint(alloc, "{s}side:{c}\n", .{ positionStr, SideChar[@enumToInt(self.Side)] });

        var enPassantFile: u8 = '-';
        if (self.bitboards.get(.EP) != 0) {
            enPassantFile = @ctz(self.bitboards.get(.EP));
        }
        positionStr = try std.fmt.allocPrint(alloc, "{s}enPasFile:{c}\n", .{ positionStr, enPassantFile });

        // Compute castling permissions
        var wKCA: u8 = '-';
        if (self.castlePermissions & WhiteKingCastling != 0) {
            wKCA = 'K';
        }

        var wQCA: u8 = '-';
        if (self.castlePermissions & WhiteQueenCastling != 0) {
            wQCA = 'Q';
        }

        var bKCA: u8 = '-';
        if (self.castlePermissions & BlackKingCastling != 0) {
            bKCA = 'k';
        }

        var bQCA: u8 = '-';
        if (self.castlePermissions & BlackQueenCastling != 0) {
            bQCA = 'q';
        }

        positionStr = try std.fmt.allocPrint(alloc, "{s}castle:{c}{c}{c}{c}\n", .{ positionStr, wKCA, wQCA, bKCA, bQCA });
        positionStr = try std.fmt.allocPrint(alloc, "{s}PosKey:{d}\n", .{ positionStr, self.positionKey });

        return positionStr;
    }
    // ParseFen parse fen position string and setup a position accordingly
    pub fn parse_fen(self: *Board, fen: []const u8) !void {
        var piece: BitBoardIdx = .NoPiece;
        var count: u8 = 0; // number of empty squares declared inside fen string

        self.reset();
        var char: u8 = 0;
        const fen_len = fen.len;

        while ((count < 64) and (char < fen_len)) {
            const t = fen[char];
            switch (t) {
                'p', 'r', 'n', 'b', 'k', 'q', 'P', 'R', 'N', 'B', 'K', 'Q' => {
                    var buf: [1]u8 = undefined;
                    const pieceStr = try std.fmt.bufPrint(&buf, "{c}", .{t});
                    if (PieceNotationMap.get(pieceStr)) |p| {
                        piece = p;
                    }
                },
                '1', '2', '3', '4', '5', '6', '7', '8' => {
                    // otherwise it must be a count of a number of empty squares
                    const empty = t - '0'; // get number of empty squares and store in count
                    count += empty;
                    char += 1;
                    continue;
                },
                '/', ' ' => {
                    // if we have / or space then we are either at the end of the rank or at the end of the piece list
                    // -> reset variables and continue the while loop
                    char += 1;
                    continue;
                },
                else => {
                    return error.FenError;
                },
            }
            // compute piece color based on piece type
            var color: Color = .Black;
            if (@enumToInt(piece) < @enumToInt(BitBoardIdx.BP)) {
                color = .White;
            }

            const pieceBitboard = self.bitboards.get(piece);
            self.bitboards.set(piece, pieceBitboard | (@intCast(u64, 1) << @intCast(u6, count)));
            self.position[count] = piece;
            self.positionKey ^= PieceKeys[@enumToInt(piece)][count];
            char += 1;
            count += 1;
        }

        var newChar: u8 = undefined;
        char += 1; // move char from empty space to the w/b part of FEN
        // newChar should be set to the side to move part of the FEN string here
        newChar = fen[char];
        switch (newChar) {
            'w' => {
                self.Side = .White;
                // hash side (side key is only added for one side)
                self.positionKey ^= SideKey;
            },
            'b' => self.Side = .Black,
            else => return error.UnknownSideToMove,
        }

        // move char pointer 2 chars further and it should now point to the start of the castling permissions part of FEN
        char += 2;

        // Iterate over the next 4 chars - they show if white is allowed to castle king or quenside and the same for black
        inline for (0..4) |_| {
            newChar = fen[char];

            switch (newChar) { // Depending on the char, enable the corresponding castling permission related bit
                ' ' => break, // when we hit a space, it means there are no more castling permissions => break
                'K' => self.castlePermissions |= WhiteKingCastling,
                'Q' => self.castlePermissions |= WhiteQueenCastling,
                'k' => self.castlePermissions |= BlackKingCastling,
                'q' => self.castlePermissions |= BlackQueenCastling,
                else => break,
            }

            char += 1;
        }

        // hash castle permissions
        self.positionKey ^= CastleKeys[self.castlePermissions];

        // AssertTrue(pos.castlePerm >= 0 && pos.castlePerm <= 15)
        // move to the en passant square related part of FEN
        char += 1;
        newChar = fen[char];

        if (newChar != '-') {
            const file = newChar - 'a';
            char += 1;

            if (file < 0 or file > 7) {
                return error.FileOutOfBounds;
            }

            self.bitboards.set(.EP, FileMasks8[file]);
            // hash en passant
            self.positionKey ^= PieceKeys[@enumToInt(BitBoardIdx.EP)][@ctz(self.bitboards.get(.EP))];
        }
    }
};

pub fn new() Board {
    var b = Board{
        .position = undefined,
        .bitboards = std.EnumArray(BitBoardIdx, u64).initFill(0),
        .stateBoards = std.EnumArray(StateBoardIdx, u64).initFill(0),
        .Side = Color.White,
        .castlePermissions = 0,
        .ply = 0,
        .fiftyMove = 0,
        .positionKey = 0,
        .history = undefined,
    };
    b.reset();
    return b;
}

//
// // UpdateBitMasks Updates all move generation/making related bit masks
// func (board *Board) UpdateBitMasks() {
// 	if board.Side == White {
// 		board.stateBoards[NotMyPieces] = ^(board.bitboards[WP] |
// 			board.bitboards[WN] |
// 			board.bitboards[WB] |
// 			board.bitboards[WR] |
// 			board.bitboards[WQ] |
// 			board.bitboards[WK] |
// 			board.bitboards[BK])
//
// 		board.stateBoards[MyPieces] = (board.bitboards[WP] |
// 			board.bitboards[WN] |
// 			board.bitboards[WB] |
// 			board.bitboards[WR] |
// 			board.bitboards[WQ])
//
// 		board.stateBoards[EnemyPieces] = (board.bitboards[BP] |
// 			board.bitboards[BN] |
// 			board.bitboards[BB] |
// 			board.bitboards[BR] |
// 			board.bitboards[BQ])
//
// 		board.stateBoards[Occupied] = (board.bitboards[WP] |
// 			board.bitboards[WN] |
// 			board.bitboards[WB] |
// 			board.bitboards[WR] |
// 			board.bitboards[WQ] |
// 			board.bitboards[WK] |
// 			board.bitboards[BP] |
// 			board.bitboards[BN] |
// 			board.bitboards[BB] |
// 			board.bitboards[BR] |
// 			board.bitboards[BQ] |
// 			board.bitboards[BK])
//
// 		board.stateBoards[EnemyRooksQueens] = (board.bitboards[BQ] | board.bitboards[BR])
// 		board.stateBoards[EnemyBishopsQueens] = (board.bitboards[BQ] | board.bitboards[BB])
// 		board.stateBoards[EnemyKnights] = board.bitboards[BN]
// 		board.stateBoards[EnemyPawns] = board.bitboards[BP]
//
// 		board.stateBoards[Empty] = ^board.stateBoards[Occupied]
// 		board.stateBoards[Unsafe] = board.unsafeForWhite()
// 	} else {
// 		board.stateBoards[NotMyPieces] = ^(board.bitboards[BP] |
// 			board.bitboards[BN] |
// 			board.bitboards[BB] |
// 			board.bitboards[BR] |
// 			board.bitboards[BQ] |
// 			board.bitboards[BK] |
// 			board.bitboards[WK])
//
// 		board.stateBoards[MyPieces] = (board.bitboards[BP] |
// 			board.bitboards[BN] |
// 			board.bitboards[BB] |
// 			board.bitboards[BR] |
// 			board.bitboards[BQ])
//
// 		board.stateBoards[EnemyPieces] = (board.bitboards[WP] |
// 			board.bitboards[WN] |
// 			board.bitboards[WB] |
// 			board.bitboards[WR] |
// 			board.bitboards[WQ])
//
// 		board.stateBoards[Occupied] = (board.bitboards[WP] |
// 			board.bitboards[WN] |
// 			board.bitboards[WB] |
// 			board.bitboards[WR] |
// 			board.bitboards[WQ] |
// 			board.bitboards[WK] |
// 			board.bitboards[BP] |
// 			board.bitboards[BN] |
// 			board.bitboards[BB] |
// 			board.bitboards[BR] |
// 			board.bitboards[BQ] |
// 			board.bitboards[BK])
//
// 		board.stateBoards[EnemyRooksQueens] = (board.bitboards[WQ] | board.bitboards[WR])
// 		board.stateBoards[EnemyBishopsQueens] = (board.bitboards[WQ] | board.bitboards[WB])
// 		board.stateBoards[EnemyKnights] = board.bitboards[WN]
// 		board.stateBoards[EnemyPawns] = board.bitboards[WP]
//
// 		board.stateBoards[Empty] = ^board.stateBoards[Occupied]
// 		board.stateBoards[Unsafe] = board.unsafeForBlack()
// 	}
// }
//
// // GetMoves Returns a struct that holds all the possible moves for a given position
// func (board *Board) GetMoves() (moveList MoveList) {
// 	if board.Side == White {
// 		board.LegalMovesWhite(&moveList)
// 	} else {
// 		board.LegalMovesBlack(&moveList)
// 	}
// 	return moveList
// }
//
