#include "game.h"

#ifdef __linux__
// Use default visibility for exported symbols
#define EXPORT __attribute__((visibility("default")))
#else
#define EXPORT ""
#endif

extern "C" {
EXPORT Game* gameInit() {
    Game* game = new Game();
    return game;
}
EXPORT void gameClose(Game* game) { game->close(); }
EXPORT void gameTick(Game* game) { game->tick(); }
EXPORT bool gameShouldClose(Game* game) { return game->shouldClose(); }
EXPORT void gameSetTitle(Game* game, const char* title) {
    game->setTitle(title);
}
}
