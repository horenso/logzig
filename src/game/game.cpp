#include "game.h"

#include <cmath>
#include <format>
#include <raymath.h>

Game::Game()
    : m_camera({{0, 0},
                {static_cast<float>(c_width) / 2.0f,
                 static_cast<float>(c_height) / 2.0f},
                1.0f,
                0.0f}),
      m_mode(Mode::Navigate), m_showGrid(false), m_hoverPos(std::nullopt),
      m_statusText("") {}

void Game::init() {
    InitWindow(c_width, c_height, "Game");
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    SetTargetFPS(60);
    SetExitKey(0);
}

void Game::close() { CloseWindow(); }

void Game::tick() {
    input();
    draw();
}

bool Game::shouldClose() const { return WindowShouldClose(); }

void Game::setTitle(const char* newTitle) { SetWindowTitle(newTitle); }

void Game::input() {
    const float panSpeed = 5.0f;
    float zoom = m_camera.zoom;

    if (IsKeyDown(KEY_W)) {
        m_camera.target.y -= panSpeed / zoom;
    }
    if (IsKeyDown(KEY_A)) {
        m_camera.target.x -= panSpeed / zoom;
    }
    if (IsKeyDown(KEY_S)) {
        m_camera.target.y += panSpeed / zoom;
    }
    if (IsKeyDown(KEY_D)) {
        m_camera.target.x += panSpeed / zoom;
    }

    if (IsKeyPressed(KEY_LEFT_BRACKET)) {
        m_camera.zoom = std::max(1.0f, zoom / 2.0f);
    }
    if (IsKeyPressed(KEY_RIGHT_BRACKET)) {
        m_camera.zoom = std::min(8.0f, zoom * 2.0f);
    }
    if (IsKeyPressed(KEY_C)) {
        m_mode = Mode::ConnectorNew;
    }

    Vector2 mousePos = GetScreenToWorld2D(GetMousePosition(), m_camera);
    int tileX = static_cast<int>(std::floor(mousePos.x / c_gridSize));
    int tileY = static_cast<int>(std::floor(mousePos.y / c_gridSize));

    if (tileX >= 0 && tileX < c_grids && tileY >= 0 && tileY < c_grids) {
        m_hoverPos = Vector2Int{tileX, tileY};
    } else {
        m_hoverPos.reset();
    }

    if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
        if (m_hoverPos.has_value()) {
            Vector2Int newPos = m_hoverPos.value();
            if (m_mode == Mode::Navigate) {
                Vector2 delta = GetMouseDelta();
                delta = Vector2Scale(delta, -1.0f / m_camera.zoom);
                m_camera.target = Vector2Add(m_camera.target, delta);
            }

            if (!m_objects.contains(newPos)) {
                m_objects[newPos] = Gate::And;
            }
        }
    }

    if (IsKeyPressed(KEY_SPACE)) {
        m_camera.target = Vector2{};
    }
}
}

void Game::draw() {
    BeginDrawing();
    ClearBackground(WHITE);

    BeginMode2D(game->camera);

    // Draw level bounding rectangle
    DrawRectangleLines(0, 0, c_gridSize * grids, grid_size * grids, RED);

    // Draw grid
    for (int x = 0; x < grids; ++x) {
        for (int y = 0; y < grids; ++y) {
            DrawRectangle(grid_size * x + grid_size / 2,
                          grid_size * y + grid_size / 2, 2, 2, RED);
        }
    }

    // Draw objects
    for (const auto& [pos, gate] : game->objects) {
        DrawRectangleLinesEx({static_cast<float>(pos.x * grid_size),
                              static_cast<float>(pos.y * grid_size),
                              static_cast<float>(grid_size),
                              static_cast<float>(grid_size)},
                             2.0f, BLUE);
    }

    EndMode2D();

    // Draw UI
    DrawRectangle(0, 0, GetScreenWidth(), 20, LIGHTGRAY);

    if (m_hoverPos.has_value()) {
        m_statusText =
            std::format("Position {} {}", m_hoverPos->x, m_hoverPos->y);
    } else {
        m_statusText = "";
    }

    DrawText(m_statusText.c_str(), 10, 0, 20, RED);

    EndDrawing();
}
