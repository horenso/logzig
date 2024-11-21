const std = @import("std");
const rl = @import("raylib.zig");
const log = std.log;

const width = 800;
const height = 600;

pub const State = enum {
    drag,
    place,
};

pub const Game = struct {
    camera: rl.Camera2D = rl.Camera2D{
        .target = rl.Vector2{ .x = -100, .y = -100 },
        .offset = rl.Vector2{ .x = @as(f32, @floatFromInt(width)) / 2.0, .y = @as(f32, @floatFromInt(height)) / 2.0 },
        .zoom = 1,
        .rotation = 0,
    },
    state: State = .place,
    // objects: []

    pub fn init() *Game {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        const game = allocator.create(Game) catch @panic("out of memory");

        rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
        rl.InitWindow(width, height, "");
        rl.SetTargetFPS(60);
        rl.SetExitKey(0);

        return game;
    }

    pub fn close(self: *Game) void {
        _ = self;
        rl.CloseWindow();
    }

    fn input(self: *Game) void {
        if (rl.IsKeyDown(rl.KEY_W)) self.camera.target.y -= 1;
        if (rl.IsKeyDown(rl.KEY_A)) self.camera.target.x -= 1;
        if (rl.IsKeyDown(rl.KEY_S)) self.camera.target.y += 1;
        if (rl.IsKeyDown(rl.KEY_D)) self.camera.target.x += 1;
    }

    fn draw(self: *Game) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.WHITE);
        rl.DrawFPS(10, 10);

        log.info("camera: {} ", .{self.camera});

        // {
        //     // rl.BeginMode2D(self.camera);
        //     // defer rl.EndMode2D();

        //     var x: c_int = 0;
        //     while (x < rl.GetScreenWidth()) {
        //         var y: c_int = 0;
        //         while (y < rl.GetScreenHeight()) {
        //             rl.DrawRectangle(x, y, 10, 10, rl.RED);
        //             y += 100;
        //         }
        //         x += 100;
        //     }
        // }
        rl.DrawText("Hello", 0, 0, 30, rl.BLACK);
        {
            rl.BeginMode2D(self.camera);

            rl.DrawRectangle(-100, -100, 1000, 1000, rl.RED);
            rl.DrawText("Hello", 0, 0, 30, rl.BLACK);

            rl.EndMode2D();
        }
    }

    pub fn tick(self: *Game) void {
        self.input();
        self.draw();
    }

    pub fn shouldClose(self: *Game) bool {
        _ = self;
        return rl.WindowShouldClose();
    }

    pub fn setTitle(self: *Game, new_title: [*c]const u8) void {
        _ = self;
        return rl.SetWindowTitle(new_title);
    }
};
