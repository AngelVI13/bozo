const std = @import("std");
const board = @import("board.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const alloc = arena.allocator();

    try board.new(alloc);
    // b.reset();
    // std.debug.print("\n{s}\n", .{try b.stringify()});
}
