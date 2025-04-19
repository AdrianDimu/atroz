const std = @import("std");
const Orbit = @import("orbit.zig").Orbit;

pub const Point = struct { x: f32, y: f32 };

pub const Body = struct {
    name: []const u8,
    radius: f32,
    color: [3]u8,
    orbit: ?*Orbit, // null for sun
    trail: []Point,
    trail_index: usize = 0,
    position_override: ?Point = null, // for setting sun position

    pub fn update(self: *Body, dt: f32) void {
        if (self.orbit) |o| o.update(dt);
        self.trail[self.trail_index] = self.position();
        self.trail_index = (self.trail_index + 1) % self.trail.len;
    }

    pub fn position(self: *const Body) Point {
        if (self.orbit) |o| return o.position();
        if (self.position_override) |p| return p;
        return Point{ .x = 0, .y = 0 }; //fallback
    }

    /// Factory initializer that fills the trail with initial position.
    pub fn init(
        name: []const u8,
        radius: f32,
        color: [3]u8,
        orbit: ?*Orbit,
        trail: []Point,
        position_override: ?Point,
    ) Body {
        var body = Body{
            .name = name,
            .radius = radius,
            .color = color,
            .orbit = orbit,
            .trail = trail,
            .position_override = position_override,
        };

        const pos = body.position();
        for (trail) |*p| p.* = pos;

        return body;
    }
};
