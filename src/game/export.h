#pragma once

#include "game.h"

extern "C" {
Game* gameInit() {
    Game* game = new Game();
    game->init();
    return game;
}
void gameClose(Game* game) { game->close(); }
void gameTick(Game* game) { game->tick(); }
bool gameShouldClose(Game* game) { return game->shouldClose(); }
void gameSetTitle(Game* game, const char* title) { game->setTitle(title); }
}
