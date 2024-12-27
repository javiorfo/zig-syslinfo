const std = @import("std");
const testing = std.testing;

pub const ZONE = enum(u4) {
    zero,
    one,
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,

    pub fn getValue(self: ZONE) u4 {
        return @intFromEnum(self);
    }
};

const ThermalInfo = struct {};

test "thermal" {
    try testing.expect(ZONE.zero.getValue() == 0);
}
