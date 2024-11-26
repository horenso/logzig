#pragma once

#include "raylib.h"

#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

struct Vector2Int {
    int x, y;

    bool operator==(const Vector2Int& other) const {
        return x == other.x && y == other.y;
    }

    bool operator!=(const Vector2Int& other) const { return !(*this == other); }
};

namespace std {
template <> struct hash<Vector2Int> {
    std::size_t operator()(const Vector2Int& v) const noexcept {
        return std::hash<int>()(v.x) ^ (std::hash<int>()(v.y) << 1);
    }
};
} // namespace std

enum class Mode {
    Navigate,
    ConnectorNew,
    PlaceObjects,
};

enum class Gate {
    And,
};

class Game {
  public:
    Game();
    ~Game() = default;

    void close();
    void tick();
    bool shouldClose() const;
    void setTitle(const char* newTitle);

  private:
    void input();
    void draw();

    Camera2D m_camera;
    Mode m_mode;
    bool m_showGrid;
    // std::vector<std::array<int, 4>> m_connectors;
    std::unordered_map<Vector2Int, Gate> m_objects;
    std::optional<Vector2Int> m_hoverPos;
    std::string m_statusText;

    static constexpr int c_gridSize = 32;
    static constexpr int c_grids = 20;
    static constexpr float c_panSpeed = 5.0f;
};
