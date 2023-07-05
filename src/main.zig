const std = @import("std");
const board = @import("board.zig");
const hash = @import("hashkey.zig");

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

    try hash.init_hash_keys();

    var b = board.new();
    try b.parse_fen(board.StartingPosition);

    std.debug.print("]\n\n{s}\n", .{try b.stringify(alloc)});
}
