const std = @import("std");
const body = @import("body.zig");
const Body = body.Body;
const Point = body.Point;

const sdl = @import("../sdl.zig");

/// Draw a circular body using a brute-force pixel fill.
pub fn drawBody(renderer: ?*sdl.SDL_Renderer, b: *const Body) void {
    const pos = b.position();
    const cx = @as(i32, @intFromFloat(pos.x));
    const cy = @as(i32, @intFromFloat(pos.y));
    const r = @as(i32, @intFromFloat(b.radius));

    _ = sdl.SDL_SetRenderDrawColor(renderer, b.color[0], b.color[1], b.color[2], 255);

    var y: i32 = -r;
    while (y <= r) : (y += 1) {
        var x: i32 = -r;
        while (x <= r) : (x += 1) {
            if (x * x + y * y <= r * r) {
                _ = sdl.SDL_RenderDrawPoint(renderer, cx + x, cy + y);
            }
        }
    }
}

/// Draw a fading trail of lines from trail buffer.
pub fn drawTrail(renderer: ?*sdl.SDL_Renderer, trail: []const Point, start_index: usize, color: [3]u8) void {
    var i: usize = 0;
    while (i < trail.len - 1) : (i += 1) {
        const a = trail[(start_index + i) % trail.len];
        const b = trail[(start_index + i + 1) % trail.len];

        const alpha = @as(u8, @intFromFloat(@as(f32, @floatFromInt(255 * i)) / @as(f32, @floatFromInt(trail.len))));

        _ = sdl.SDL_SetRenderDrawColor(renderer, color[0], color[1], color[2], alpha);

        _ = sdl.SDL_RenderDrawLine(
            renderer,
            @as(i32, @intFromFloat(a.x)),
            @as(i32, @intFromFloat(a.y)),
            @as(i32, @intFromFloat(b.x)),
            @as(i32, @intFromFloat(b.y)),
        );
    }
}

/// Renders a text label at the specified screen coordinates.
pub fn drawLabel(
    renderer: ?*sdl.SDL_Renderer,
    font: ?*sdl.TTF_Font,
    text: []const u8,
    x: i32,
    y: i32,
    color: sdl.SDL_Color,
) void {
    const surface = sdl.TTF_RenderText_Solid(font, text.ptr, color);
    if (surface == null) return;

    const texture = sdl.SDL_CreateTextureFromSurface(renderer, surface);
    if (texture == null) {
        sdl.SDL_FreeSurface(surface);
        return;
    }

    var dst = sdl.SDL_Rect{
        .x = x,
        .y = y,
        .w = surface.*.w,
        .h = surface.*.h,
    };

    _ = sdl.SDL_RenderCopy(renderer, texture, null, &dst);
    sdl.SDL_FreeSurface(surface);
    sdl.SDL_DestroyTexture(texture);
}

/// Renders a text on multiple lines.
pub fn drawMultilineLabel(
    renderer: ?*sdl.SDL_Renderer,
    font: ?*sdl.TTF_Font,
    text: []const u8,
    x: i32,
    y: i32,
    color: sdl.SDL_Color,
) void {
    var start: usize = 0;
    var line_index: usize = 0;

    while (start < text.len) {
        const end = std.mem.indexOfScalarPos(u8, text, start, '\n') orelse text.len;
        const line = text[start..end];

        const surface = sdl.TTF_RenderText_Solid(font, line.ptr, color);
        if (surface == null) return;

        const texture = sdl.SDL_CreateTextureFromSurface(renderer, surface);
        if (texture == null) return;

        var dst = sdl.SDL_Rect{
            .x = x,
            .y = y + @as(i32, @intCast(line_index)) * @as(i32, surface.*.h),
            .w = surface.*.w,
            .h = surface.*.h,
        };

        _ = sdl.SDL_RenderCopy(renderer, texture, null, &dst);
        sdl.SDL_FreeSurface(surface);
        sdl.SDL_DestroyTexture(texture);

        line_index += 1;
        start = end + 1; // skip newline
    }
}
