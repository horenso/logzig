const Game = @import("game.zig").Game;

export fn gameInit() *Game {
    return Game.init();
}

export fn gameDeinit(game: *Game) void {
    game.deinit();
}

export fn gameTick(game: *Game) void {
    game.tick();
}

export fn gameShouldClose(game: *Game) bool {
    return game.shouldClose();
}
