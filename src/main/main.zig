const std = @import("std");
const os = std.os;

const signal = @cImport({
    @cInclude("signal.h");
});

const LIBRARY_PATH = "zig-out/lib/libgame.so";

var game_dyn_lib: ?std.DynLib = null;

fn load_game_library() !void {
    if (game_dyn_lib) |*dyn_lib| {
        dyn_lib.close();
        game_dyn_lib = null;
    }
    var dyn_lib = std.DynLib.open(LIBRARY_PATH) catch {
        return error.OpenFail;
    };
    game_dyn_lib = dyn_lib;

    gameInit = dyn_lib.lookup(@TypeOf(gameInit), "gameInit") orelse return error.LookupFail;
    gameDeinit = dyn_lib.lookup(@TypeOf(gameDeinit), "gameDeinit") orelse return error.LookupFail;
    gameTick = dyn_lib.lookup(@TypeOf(gameTick), "gameTick") orelse return error.LookupFail;
    gameShouldClose = dyn_lib.lookup(@TypeOf(gameShouldClose), "gameShouldClose") orelse return error.LookupFail;

    std.log.info("Game refreshed", .{});
}

const Game = anyopaque;

var gameInit: *const fn () *Game = undefined;
var gameDeinit: *const fn (*Game) void = undefined;
var gameTick: *const fn (*Game) void = undefined;
var gameShouldClose: *const fn (*Game) bool = undefined;

var reload_game = false;

fn sigintHandler(_: c_int) callconv(.C) void {
    std.log.info("Reloading...", .{});
    reload_game = true;
}

pub fn main() !void {
    _ = signal.signal(signal.SIGUSR1, &sigintHandler);

    try load_game_library();

    const game = gameInit();

    var quit = false;

    while (!quit) {
        if (reload_game) {
            try load_game_library();
            reload_game = false;
        }
        gameTick(game);
        quit = gameShouldClose(game);
    }
    gameDeinit(game);
}
