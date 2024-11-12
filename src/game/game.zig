const std = @import("std");
const rl = @import("raylib.zig");

const player_w = 10;
const player_h = 10;

const cubePosition = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };
const cubeSize = rl.Vector3{ .x = 2.0, .y = 2.0, .z = 2.0 };

pub const Game = struct {
    x: f32 = 10,
    y: f32 = 10,
    points: i32 = 0,
    camera: rl.Camera,
    show_cursor: bool = true,

    pub fn init() *Game {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        const game = allocator.create(Game) catch @panic("out of memory");

        rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
        rl.InitWindow(800, 800, "hello world!");
        rl.SetTargetFPS(60);
        rl.DisableCursor();
        rl.SetExitKey(0);

        const camera = rl.Camera{
            .position = rl.Vector3{ .x = 10.0, .y = 10.0, .z = 10.0 },
            .target = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 },
            .up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
            .fovy = 45.0,
            .projection = rl.CAMERA_PERSPECTIVE,
        };

        game.x = 0;
        game.y = 0;
        game.points = 0;
        game.camera = camera;

        return game;
    }

    pub fn deinit(self: *Game) void {
        _ = self;

        rl.CloseWindow();
    }

    pub fn update_camera(self: *Game) void {
        const up: f32 = if (rl.IsKeyDown(rl.KEY_W)) 0.1 else 0;
        const down: f32 = if (rl.IsKeyDown(rl.KEY_S)) 0.1 else 0;
        const left: f32 = if (rl.IsKeyDown(rl.KEY_A)) 0.1 else 0;
        const right: f32 = if (rl.IsKeyDown(rl.KEY_D)) 0.1 else 0;

        const yaw: f32 = rl.GetMouseDelta().x * 0.05;
        const pitch: f32 = rl.GetMouseDelta().y * 0.05;

        rl.UpdateCameraPro(
            &self.camera,
            rl.Vector3{ .x = up - down, .y = right - left, .z = 0.0 },
            rl.Vector3{ .x = yaw, .y = pitch, .z = 0.0 },
            rl.GetMouseWheelMove() * 2.0,
        );
    }

    pub fn tick(self: *Game) void {
        self.update_camera();
        if (rl.IsKeyPressed(rl.KEY_ESCAPE)) {
            self.show_cursor = !self.show_cursor;
            if (self.show_cursor) {
                rl.EnableCursor();
            } else {
                rl.DisableCursor();
            }
        }

        rl.BeginDrawing();

        rl.ClearBackground(rl.BLACK);

        rl.BeginMode3D(self.camera);

        rl.DrawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.RED);
        rl.DrawGrid(100, 1.0);

        rl.EndMode3D();

        rl.DrawFPS(10, 10);

        rl.EndDrawing();
    }

    pub fn shouldClose(self: *Game) bool {
        _ = self;
        return rl.WindowShouldClose();
    }
};
