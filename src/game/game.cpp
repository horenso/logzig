#include "game.h"
#include "global.h"

#include <cmath>
#include <format>
#include <iostream>

#include <raymath.h>

Game::Game()
    : m_camera({0}), m_mode(Mode::Navigate), m_showGrid(false),
      m_hoverPos(std::nullopt), m_statusText("") {
    m_camera.target = (Vector2){0.0f, 0.0f};
    m_camera.offset = (Vector2){static_cast<float>(Global::width) / 2.0f,
                                static_cast<float>(Global::height) / 2.0f};
    m_camera.rotation = 0.0f;
    m_camera.zoom = 1.0f;
}

void Game::close() { CloseWindow(); }

void Game::tick() {
    input();
    draw();
}

bool Game::shouldClose() const { return WindowShouldClose(); }

void Game::setTitle(const char* newTitle) { SetWindowTitle(newTitle); }

void Game::input() {
    float zoom = m_camera.zoom;

    if (IsKeyDown(KEY_W)) {
        m_camera.target.y -= c_panSpeed / zoom;
    }
    if (IsKeyDown(KEY_A)) {
        m_camera.target.x -= c_panSpeed / zoom;
    }
    if (IsKeyDown(KEY_S)) {
        m_camera.target.y += c_panSpeed / zoom;
    }
    if (IsKeyDown(KEY_D)) {
        m_camera.target.x += c_panSpeed / zoom;
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

    Vector2 mouse_pos = GetScreenToWorld2D(GetMousePosition(), m_camera);
    int tile_x = static_cast<int>(std::floor(mouse_pos.x / c_gridSize));
    int tile_y = static_cast<int>(std::floor(mouse_pos.y / c_gridSize));

    if (tile_x >= 0 && tile_x < c_grids && tile_y >= 0 && tile_y < c_grids) {
        m_hoverPos = Vector2Int{tile_x, tile_y};
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

void Game::draw() {
    BeginDrawing();
    ClearBackground(WHITE);

    BeginMode2D(m_camera);

    // Draw level bounding rectangle
    DrawRectangleLines(0, 0, c_gridSize * c_grids, c_gridSize * c_grids, RED);

    // Draw grid
    for (int x = 0; x < c_grids; ++x) {
        for (int y = 0; y < c_grids; ++y) {
            DrawRectangle(c_gridSize * x + c_gridSize / 2,
                          c_gridSize * y + c_gridSize / 2, 2, 2, RED);
        }
    }

    // Draw objects
    for (const auto& [pos, gate] : m_objects) {
        DrawRectangleLinesEx({static_cast<float>(pos.x * c_gridSize),
                              static_cast<float>(pos.y * c_gridSize),
                              static_cast<float>(c_gridSize),
                              static_cast<float>(c_gridSize)},
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
