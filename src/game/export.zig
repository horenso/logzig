const std = @import("std");
const Game = @import("game.zig").Game;

export fn gameInit(allocator: *anyopaque) *Game {
    const alloc: *std.mem.Allocator = @ptrCast(@alignCast(allocator));
    return Game.init(alloc);
}

export fn gameClose(game: *Game) void {
    game.close();
}

export fn gameTick(game: *Game) void {
    game.tick();
}

export fn gameShouldClose(game: *Game) bool {
    return game.shouldClose();
}

export fn gameSetTitle(game: *Game, new_title: [*c]const u8) void {
    game.setTitle(new_title);
}
