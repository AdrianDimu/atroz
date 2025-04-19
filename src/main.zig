const std = @import("std");
const sdl = @import("sdl.zig");
const body = @import("astro/body.zig");
const Body = body.Body;
const Point = body.Point;
const orbit_mod = @import("astro/orbit.zig");
const Orbit = orbit_mod.Orbit;
const renderer_mod = @import("astro/renderer.zig");

pub fn main() !void {
    // -----------------------------------
    // Initialization
    // -----------------------------------

    // Initialize SDL
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        std.debug.print("SDL_Init Error: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLInitFailed;
    }

    // Initialize TTF
    if (sdl.TTF_Init() != 0) {
        std.debug.print("TTF_Init Error: {s}\n", .{sdl.TTF_GetError()});
        return error.TTFInitFailed;
    }

    // Window setup
    const WINDOW_WIDTH = 1000;
    const WINDOW_HEIGHT = 1000;

    const window = sdl.SDL_CreateWindow(
        "AstroZ",
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        sdl.SDL_WINDOW_SHOWN,
    );

    if (window == null) {
        std.debug.print("SDL_CreateWindow Error: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLCreateWindowFailed;
    }

    // Renderer setup
    const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED);
    if (renderer == null) {
        std.debug.print("SDL_CreateRenderer Error: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLCreateRendererFailed;
    }

    _ = sdl.SDL_SetRenderDrawBlendMode(renderer, sdl.SDL_BLENDMODE_BLEND); // added the option for transparency

    // Font setup
    const font = sdl.TTF_OpenFont("/Users/blk/Desktop/projects/zig/astroz/resources/JetBrainsMonoNLNerdFontMono-Regular.ttf", 14);
    if (font == null) {
        std.debug.print("TTF_OpenFont Error: {s}\n", .{sdl.TTF_GetError()});
    }

    // -----------------------------------
    // Setup Simulation State
    // -----------------------------------

    // Initialize trail points
    const MaxTrailPoints = 256;

    var trail_dummy: [1]Point = undefined;
    var trail_x: [MaxTrailPoints]Point = undefined;
    var trail_y: [MaxTrailPoints]Point = undefined;
    var trail_z: [MaxTrailPoints]Point = undefined;
    var trail_moon_x: [MaxTrailPoints]Point = undefined;

    // Set up Sun
    var sun = Body.init("Sun", 5, .{ 255, 255, 0 }, null, &trail_dummy, Point{ .x = WINDOW_WIDTH / 2, .y = WINDOW_HEIGHT / 2 });

    // Initialize orbit instances
    var orbit_x = Orbit.init(&sun, 100, 1.0, 0.0);
    var orbit_y = Orbit.init(&sun, 160, 0.6, 1.0);
    var orbit_z = Orbit.init(&sun, 220, 0.3, 2.5);

    // Initialize the planets
    var planetx = Body.init("PlanetX", 2, .{ 0, 200, 255 }, &orbit_x, &trail_x, null);
    var planety = Body.init("PlanetY", 3, .{ 255, 100, 100 }, &orbit_y, &trail_y, null);
    var planetz = Body.init("PlanetZ", 6, .{ 255, 200, 150 }, &orbit_z, &trail_z, null);

    // Set up moon
    var orbit_moon_x = Orbit.init(&planetx, 30, 2.5, 0.0);
    var moonx = Body.init("MoonX", 1.5, .{ 200, 200, 200 }, &orbit_moon_x, &trail_moon_x, null);

    const bodies = &[_]*Body{
        &sun,
        &planetx,
        &planety,
        &planetz,
        &moonx,
    };

    var event: sdl.SDL_Event = undefined;

    const frame_delay_ms: u32 = 16;
    var orbit_speed_multiplier: f32 = 1.0;

    const allocator = std.heap.c_allocator;

    // -----------------------------------
    // Main Loop
    // -----------------------------------
    var selected_index: usize = 0;
    var running = true;

    while (running) {
        // Handle Input
        while (sdl.SDL_PollEvent(&event) != 0) {
            if (event.type == sdl.SDL_QUIT) {
                running = false;
            } else if (event.type == sdl.SDL_KEYDOWN) {
                const key = event.key.keysym.sym;

                switch (key) {
                    sdl.SDLK_TAB => {
                        selected_index = (selected_index + 1) % bodies.len;
                    },
                    sdl.SDLK_1 => bodies[selected_index].radius -= 0.2,
                    sdl.SDLK_2 => bodies[selected_index].radius += 0.2,
                    sdl.SDLK_3 => {
                        if (bodies[selected_index].orbit) |o| o.*.radius -= 2;
                    },
                    sdl.SDLK_4 => {
                        if (bodies[selected_index].orbit) |o| o.*.radius += 2;
                    },
                    sdl.SDLK_5 => {
                        if (bodies[selected_index].orbit) |o| o.*.speed -= 0.05;
                    },
                    sdl.SDLK_6 => {
                        if (bodies[selected_index].orbit) |o| o.*.speed += 0.05;
                    },
                    sdl.SDLK_7 => {
                        if (bodies[selected_index].orbit) |o| o.*.angle -= 0.1;
                    },
                    sdl.SDLK_8 => {
                        if (bodies[selected_index].orbit) |o| o.*.angle += 0.1;
                    },
                    sdl.SDLK_MINUS => {
                        orbit_speed_multiplier *= 0.9;
                        if (orbit_speed_multiplier < 0.01) orbit_speed_multiplier = 0.01;
                    },
                    sdl.SDLK_EQUALS => {
                        orbit_speed_multiplier *= 1.1;
                        if (orbit_speed_multiplier > 10.0) orbit_speed_multiplier = 10.0;
                    },
                    else => {},
                }
            }
        }

        const selected = bodies[selected_index];

        // Update simulation
        const dt = 0.05 * orbit_speed_multiplier;
        for (bodies) |b| b.update(dt);

        // Clear screen
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = sdl.SDL_RenderClear(renderer);

        // Draw planets
        for (bodies) |b| {
            // Render trail
            renderer_mod.drawTrail(renderer, b.trail, b.trail_index, b.color);
            // Render body
            renderer_mod.drawBody(renderer, b);
            // Render label
            const is_selected = (b == selected);
            const label_color = if (is_selected) [3]u8{ 255, 255, 0 } else b.color;
            const sdl_color = sdl.SDL_Color{
                .r = label_color[0],
                .g = label_color[1],
                .b = label_color[2],
                .a = 255,
            };

            const pos = b.position();
            renderer_mod.drawLabel(renderer, font, b.name, @as(i32, @intFromFloat(pos.x + 10)), @as(i32, @intFromFloat(pos.y)), sdl_color);
        }

        const white = sdl.SDL_Color{
            .r = 255,
            .g = 255,
            .b = 255,
            .a = 255,
        };

        // Render control panel
        const orbit = selected.orbit;
        const orbit_radius = if (orbit) |o| o.radius else 0.0;
        const orbit_speed = if (orbit) |o| o.speed else 0.0;
        const orbit_angle = if (orbit) |o| o.angle else 0.0;

        const props_buf = try std.fmt.allocPrintZ(allocator, "Selected:     {s}\n" ++
            "Radius:       (1) [-] {d:.1} [+] (2)\n" ++
            "Orbit Radius: (3) [-] {d:.1} [+] (4)\n" ++
            "Orbit Speed:  (5) [-] {d:.2} [+] (6)\n" ++
            "Orbit Angle:  (7) [-] {d:.2} [+] (8)", .{
            selected.name,
            selected.radius,
            orbit_radius,
            orbit_speed,
            orbit_angle,
        });
        defer allocator.free(props_buf);

        renderer_mod.drawMultilineLabel(renderer, font, props_buf, 10, 30, white);

        // Render global speed display
        const speed_buf = try std.fmt.allocPrintZ(allocator, "Speed: {d:.2}", .{orbit_speed_multiplier});
        defer allocator.free(speed_buf);
        renderer_mod.drawLabel(renderer, font, speed_buf, 10, 10, white);

        // Present frame
        sdl.SDL_RenderPresent(renderer);
        sdl.SDL_Delay(frame_delay_ms);
    }

    // -----------------------------------
    // Cleanup
    // -----------------------------------

    sdl.TTF_CloseFont(font);
    sdl.TTF_Quit();
    sdl.SDL_DestroyRenderer(renderer);
    sdl.SDL_DestroyWindow(window);
    sdl.SDL_Quit();
}
