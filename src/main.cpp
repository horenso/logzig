#include <chrono>
#include <csignal>
#include <cstring>
#include <dlfcn.h>
#include <iostream>
#include <string>
#include <thread>

// Constants
const std::string LIBRARY_PATH = "./libgame.so";

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

// Helper function to load a symbol from the dynamic library
template <typename Func>
Func loadSymbol(void* library, const std::string& name) {
    dlerror(); // Clear any existing error
    auto symbol = reinterpret_cast<Func>(dlsym(library, name.c_str()));
    const char* error = dlerror();
    if (error) {
        throw std::runtime_error("Failed to load symbol: " + name + " - " +
                                 std::string(error));
    }
    return symbol;
}

// Function to load the game library
void loadGameLibrary() {
    if (game_dyn_lib) {
        dlclose(game_dyn_lib);
        game_dyn_lib = nullptr;
    }

    game_dyn_lib = dlopen(LIBRARY_PATH.c_str(), RTLD_NOW);
    if (!game_dyn_lib) {
        throw std::runtime_error("Failed to open library: " + LIBRARY_PATH +
                                 " - " + std::string(dlerror()));
    }

    // Load functions
    gameInit = loadSymbol<GameInitFunc>(game_dyn_lib, "gameInit");
    gameClose = loadSymbol<GameCloseFunc>(game_dyn_lib, "gameClose");
    gameTick = loadSymbol<GameTickFunc>(game_dyn_lib, "gameTick");
    gameShouldClose =
        loadSymbol<GameShouldCloseFunc>(game_dyn_lib, "gameShouldClose");
    gameSetTitle = loadSymbol<GameSetTitleFunc>(game_dyn_lib, "gameSetTitle");

    std::cout << "Game library loaded successfully." << std::endl;
}

int main() {
    // Set up signal handling
    std::signal(SIGUSR1, sigintHandler);

    try {
        loadGameLibrary();
    } catch (const std::exception& e) {
        std::cerr << e.what() << std::endl;
        return EXIT_FAILURE;
    }

    auto game = gameInit();

    if (!game) {
        std::cerr << "Failed to initialize game." << std::endl;
        return EXIT_FAILURE;
    }

    std::string title_buf(100, '\0');
    bool quit = false;

    while (!quit) {
        if (reload_game) {
            try {
                loadGameLibrary();
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
        quit = gameShouldClose(game);
    }

    gameClose(game);

    if (game_dyn_lib) {
        dlclose(game_dyn_lib);
    }

    return EXIT_SUCCESS;
}
