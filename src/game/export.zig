const Game = @import("game.zig").Game;

export fn gameInit() *Game {
    return Game.init();
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
