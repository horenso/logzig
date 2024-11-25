const std = @import("std");
const rl = @import("raylib.zig");
const log = std.log;

const Gate = @import("gate.zig").Gate;

const width = 800;
const height = 600;

const grid_size = 32;

const grids = 20;


const Vector2Int = @Vector(2, c_int);

const Connector = struct {
    start = Vector2Int,
    end = ?Vector2Int,
};

pub const Mode = union(enum) {
    navigate: void,
    connector_new: void,
    connectors: Connector,
    place_objects: void,
};

pub const Game = struct {
    allocator: *std.mem.Allocator,
    camera: rl.Camera2D,
    mode: Mode,
    show_grid: bool,
    connectors: std.ArrayList(@Vector(4, c_int)),
    objects: std.AutoHashMap(Vector2Int, Gate),
    hover_pos: ?Vector2Int,

    status_text: [100]u8,

    pub fn init(allocator: *std.mem.Allocator) *Game {
        const game = allocator.create(Game) catch @panic("out of memory");

        game.allocator = allocator;
        game.mode = Mode.navigate;
        game.camera = .{
            .target = rl.Vector2{ .x = 0, .y = -100 },
            .offset = rl.Vector2{
                .x = @as(f32, @floatFromInt(width)) / 2.0,
                .y = @as(f32, @floatFromInt(height)) / 2.0,
            },
            .zoom = 1,
            .rotation = 0,
        };
        game.show_grid = true;

        game.connectors = std.ArrayList(@Vector(4, c_int)).init(allocator.*);
        game.objects = std.AutoHashMap(Vector2Int, Gate).init(allocator.*);
        game.status_text = std.mem.zeroes([100]u8);

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

    fn input(self: *Game) !void {
        const pan_speed = 5.0;
        const zoom = self.camera.zoom;
        if (rl.IsKeyDown(rl.KEY_W)) self.camera.target.y -= pan_speed / zoom;
        if (rl.IsKeyDown(rl.KEY_A)) self.camera.target.x -= pan_speed / zoom;
        if (rl.IsKeyDown(rl.KEY_S)) self.camera.target.y += pan_speed / zoom;
        if (rl.IsKeyDown(rl.KEY_D)) self.camera.target.x += pan_speed / zoom;
        if (rl.IsKeyPressed(rl.KEY_LEFT_BRACKET)) self.camera.zoom = @max(1, zoom / 2);
        if (rl.IsKeyPressed(rl.KEY_RIGHT_BRACKET)) self.camera.zoom = @min(8, zoom * 2);
        if (rl.IsKeyPressed(rl.KEY_C)) self.mode = .connector_new;

        const mouse_pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), self.camera);
        const tile_x: c_int = @intFromFloat((mouse_pos.x) / grid_size);
        const tile_y: c_int = @intFromFloat((mouse_pos.y) / grid_size);

        if (tile_x >= 0 and tile_x < grids and tile_y >= 0 and tile_y < grids) {
            self.hover_pos = Vector2Int{ tile_x, tile_y };
        } else {
            self.hover_pos = null;
        }

        if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
            if (self.hover_pos) |hover_pos| {
                const new = Vector2Int{ hover_pos[0], hover_pos[1] };
                switch (self.mode) {
                    .navigate => {
                        var delta = rl.GetMouseDelta();
                        delta = rl.Vector2Scale(delta, -1.0 / self.camera.zoom);
                        self.camera.target = rl.Vector2Add(self.camera.target, delta);
                    },
                    .connectors => |e| {
                        if (maybe_end) |end| {
                            self.
                        } else {
                            self.stat
                        }
                    },
                    else => {},
                }
                if (!self.objects.contains(new)) {
                    try self.objects.put(new, Gate._and);
                }
            }
        }
        if (rl.IsKeyPressed(rl.KEY_SPACE)) self.camera.target = rl.Vector2{};
    }

    fn draw(self: *Game) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.WHITE);
        {
            rl.BeginMode2D(self.camera);
            defer rl.EndMode2D();

            // Level bounding rectangle
            rl.DrawRectangleLines(
                0,
                0,
                grid_size * grids,
                grid_size * grids,
                rl.RED,
            );

            for (0..grids) |x| {
                for (0..grids) |y| {
                    rl.DrawRectangle(
                        grid_size * @as(c_int, @intCast(x)) + grid_size / 2,
                        grid_size * @as(c_int, @intCast(y)) + grid_size / 2,
                        2,
                        2,
                        rl.RED,
                    );
                }
            }

            // Draw objects
            var object_iter = self.objects.iterator();
            while (object_iter.next()) |entry| {
                rl.DrawRectangleLinesEx(
                    rl.Rectangle{
                        .x = @floatFromInt(entry.key_ptr[0] * grid_size),
                        .y = @floatFromInt(entry.key_ptr[1] * grid_size),
                        .width = grid_size,
                        .height = grid_size,
                    },
                    2.0,
                    rl.BLUE,
                );
            }
        }
        // UI

        const font_size = 20;
        const window_width = rl.GetScreenWidth();
        {
            rl.DrawRectangle(
                0,
                0,
                @intCast(window_width),
                font_size,
                rl.LIGHTGRAY,
            );

            if (self.hover_pos) |hover_pos| {
                _ = std.fmt.bufPrint(
                    &self.status_text,
                    "Position {} {}",
                    .{ hover_pos[0], hover_pos[1] },
                ) catch unreachable;
            } else {
                self.status_text = std.mem.zeroes(@TypeOf(self.status_text));
            }

            rl.DrawText(@ptrCast(&self.status_text), 10, 0, font_size, rl.RED);
        }
    }

    pub fn tick(self: *Game) void {
        self.input() catch unreachable;
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
