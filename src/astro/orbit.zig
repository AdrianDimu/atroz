const body = @import("body.zig");
const Body = body.Body;
const Point = body.Point;

pub const Orbit = struct {
    parent: ?*const Body, // null for static orbits (like around the sun)
    radius: f32,
    speed: f32,
    angle: f32,

    pub fn init(parent: ?*const Body, radius: f32, speed: f32, angle: f32) Orbit {
        return .{
            .parent = parent,
            .radius = radius,
            .speed = speed,
            .angle = angle,
        };
    }

    pub fn update(self: *Orbit, dt: f32) void {
        self.angle += self.speed * dt;
    }

    pub fn position(self: *const Orbit) Point {
        const center = if (self.parent) |p| p.position() else Point{ .x = 0, .y = 0 };
        return Point{
            .x = center.x + self.radius * @cos(self.angle),
            .y = center.y + self.radius * @sin(self.angle),
        };
    }
};
