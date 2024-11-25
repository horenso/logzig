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
    gameClose = dyn_lib.lookup(@TypeOf(gameClose), "gameClose") orelse return error.LookupFail;
    gameTick = dyn_lib.lookup(@TypeOf(gameTick), "gameTick") orelse return error.LookupFail;
    gameShouldClose = dyn_lib.lookup(@TypeOf(gameShouldClose), "gameShouldClose") orelse return error.LookupFail;
    gameSetTitle = dyn_lib.lookup(@TypeOf(gameSetTitle), "gameSetTitle") orelse return error.LookupFail;

    std.log.info("Game refreshed", .{});
}

const Game = anyopaque;

var gameInit: *const fn (allocator: *anyopaque) *Game = undefined;
var gameClose: *const fn (*Game) void = undefined;
var gameTick: *const fn (*Game) void = undefined;
var gameShouldClose: *const fn (*Game) bool = undefined;
var gameSetTitle: *const fn (*Game, [*c]const u8) void = undefined;

var reload_game = false;

fn sigintHandler(_: c_int) callconv(.C) void {
    std.log.info("Reloading...", .{});
    reload_game = true;
}

pub fn main() !void {
    _ = signal.signal(signal.SIGUSR1, &sigintHandler);

    try load_game_library();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    const game = gameInit(@ptrCast(&allocator));

    var title_buf = std.mem.zeroes([100]u8);

    var quit = false;

    while (!quit) {
        if (reload_game) {
            try load_game_library();
            reload_game = false;
            const new_title = try std.fmt.bufPrint(&title_buf, "Logzig! ({})", .{std.time.timestamp()});
            gameSetTitle(game, @ptrCast(new_title));
        }
        gameTick(game);
        quit = gameShouldClose(game);
    }
    gameClose(game);
}
