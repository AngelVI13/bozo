const std = @import("std");
const Allocator = std.mem.Allocator;

// StartingPosition 8x8 representation of normal chess starting position
const StartingPosition: []const u8 = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

const SideChar: []const u8 = "wb-";
const PieceChar: []const u8 = ".PNBRQKpnbrqk";

// Indexes to access bitboards i.e. WP - white pawn, BB - black bishop
const BitBoardIdx = enum(u8) {
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
const Color = enum(u8) {
    White,
    Black,
    Both,
};

// MaxGameMoves Maximum number of game moves
const MaxGameMoves: u16 = 2048;
const BoardSquareNum: u8 = 64;

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
const WhiteKingCastling: u8 = 1;
const WhiteQueenCastling: u8 = 2;
const BlackKingCastling: u8 = 4;
const BlackQueenCastling: u8 = 8;

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
    material: std.EnumArray(Color, u32), // material scores for black and white
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
        self.material.set(.White, 0);
        self.material.set(.Black, 0);
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

        var positionStr: []const u8 = "\n";
        for (position, 0..position.len) |rank, idx| {
            {
                positionStr = try std.fmt.allocPrint(alloc, "{s} {d} ", .{positionStr, 8 - idx});
            }
            for (rank) |file| {
                {
                    positionStr = try std.fmt.allocPrint(alloc, "{s} {s} ", .{positionStr, file});
                }
            }
            positionStr = try std.fmt.allocPrint(alloc, "{s}\n", .{positionStr});
        }

        // positionStr += "\n     "
        // startFileIdx := "A"[0]
        // for i := startFileIdx; i < startFileIdx+8; i++ {
        // 	positionStr += fmt.Sprintf("%s  ", string(i))
        // }
        // positionStr += fmt.Sprintf("\n")

        // // ---
        // positionStr += fmt.Sprintf("side:%c\n", SideChar[self.Side])

        // enPassantFile := "-"
        // if self.bitboards[EP] != 0 {
        // 	enPassantFile = strconv.Itoa(bits.TrailingZeros64(self.bitboards[EP]))
        // }
        // positionStr += fmt.Sprintf("enPasFile:%s\n", enPassantFile)

        // // Compute castling permissions
        // wKCA := "-"
        // if self.castlePermissions&WhiteKingCastling != 0 {
        // 	wKCA = "K"
        // }

        // wQCA := "-"
        // if self.castlePermissions&WhiteQueenCastling != 0 {
        // 	wQCA = "Q"
        // }

        // bKCA := "-"
        // if self.castlePermissions&BlackKingCastling != 0 {
        // 	bKCA = "k"
        // }

        // bQCA := "-"
        // if self.castlePermissions&BlackQueenCastling != 0 {
        // 	bQCA = "q"
        // }

        // positionStr += fmt.Sprintf("castle:%s%s%s%s\n", wKCA, wQCA, bKCA, bQCA)
        // positionStr += fmt.Sprintf("PosKey:%d\n", self.positionKey)

        // // ---

        return positionStr;
    }
};

pub fn new(alloc: Allocator) !void {
    var b = Board{
        .position = undefined,
        .bitboards = std.EnumArray(BitBoardIdx, u64).initFill(0),
        .stateBoards = std.EnumArray(StateBoardIdx, u64).initFill(0),
        .Side = Color.White,
        .castlePermissions = 0,
        .material = std.EnumArray(Color, u32).initFill(0),
        .ply = 0,
        .fiftyMove = 0,
        .positionKey = 0,
        .history = undefined,
    };
    b.reset();
    const txt = try b.stringify(alloc);
    std.debug.print("\n{s}\n", .{txt});
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
