#include "game/global.h"

#include <chrono>
#include <csignal>
#include <cstring>
#include <dlfcn.h>
#include <filesystem>
#include <iostream>
#include <string>

#include <raylib.h>

using Game = void;
using GameInitFunc = Game* (*)();
using GameCloseFunc = void (*)(Game*);
using GameTickFunc = void (*)(Game*);
using GameShouldCloseFunc = bool (*)(Game*);
using GameSetTitleFunc = void (*)(Game*, const char*);

GameInitFunc gameInit = nullptr;
GameCloseFunc gameClose = nullptr;
GameTickFunc gameTick = nullptr;
GameShouldCloseFunc gameShouldClose = nullptr;
GameSetTitleFunc gameSetTitle = nullptr;

bool reload_game = false;

// Handle to the dynamic library
void* game_dyn_lib = nullptr;

// Signal handler
void sigintHandler(int) {
    std::cout << "Reloading..." << std::endl;
    reload_game = true;
}

// Function to load the game library
void loadGameLibrary(const std::string& libraryPath) {
    // Reset dlerror
    const char* error = dlerror();

    if (game_dyn_lib) {
        dlclose(game_dyn_lib);
        error = dlerror();
        if (error) {
            std::cerr << "Failed to close library: " << error << std::endl;
            exit(1);
        }
        game_dyn_lib = nullptr;
        std::cout << "library unloaded\n";
    }

    game_dyn_lib = dlopen(libraryPath.c_str(), RTLD_NOW);
    error = dlerror();
    if (error) {
        std::cerr << "Failed to open library: " << error << std::endl;
        exit(1);
    }

    // Load functions
    gameInit = reinterpret_cast<GameInitFunc>(dlsym(game_dyn_lib, "gameInit"));
    gameClose =
        reinterpret_cast<GameCloseFunc>(dlsym(game_dyn_lib, "gameClose"));
    gameTick = reinterpret_cast<GameTickFunc>(dlsym(game_dyn_lib, "gameTick"));
    gameShouldClose = reinterpret_cast<GameShouldCloseFunc>(
        dlsym(game_dyn_lib, "gameShouldClose"));
    gameSetTitle =
        reinterpret_cast<GameSetTitleFunc>(dlsym(game_dyn_lib, "gameSetTitle"));

    error = dlerror();
    if (error) {
        std::cerr << "Failed to load symbol: " << error << std::endl;
        exit(1);
    }
}

void init() {
    InitWindow(Global::width, Global::height, "Game");
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    SetTargetFPS(60);

    SetExitKey(0);

    MaximizeWindow();
}

int main() {
    // Set up signal handling
    std::signal(SIGUSR1, sigintHandler);

    std::string library_path =
        (std::filesystem::current_path() / "libgame.so").string();

    try {
        loadGameLibrary(library_path);
    } catch (const std::exception& e) {
        std::cerr << e.what() << std::endl;
        return EXIT_FAILURE;
    }

    init();
    auto game = gameInit();

    if (!game) {
        std::cerr << "Failed to initialize game." << std::endl;
        return EXIT_FAILURE;
    }

    bool quit = false;

    while (!gameShouldClose(game)) {
        if (reload_game) {
            try {
                loadGameLibrary(library_path);
                reload_game = false;
                auto timestamp =
                    std::chrono::system_clock::now().time_since_epoch().count();
                auto new_title = std::format("Logzig! ({})", timestamp);
                gameSetTitle(game, new_title.c_str());
            } catch (const std::exception& e) {
                std::cerr << e.what() << std::endl;
                return EXIT_FAILURE;
            }
        }
        gameTick(game);
    }

    gameClose(game);

    if (game_dyn_lib) {
        dlclose(game_dyn_lib);
    }

    return EXIT_SUCCESS;
}
