pub usingnamespace @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
    @cDefine("SDL_MAIN_HANDLED", "1");
});
