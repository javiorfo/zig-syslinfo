const std = @import("std");
const testing = std.testing;

pub const ThermalInfo = struct {
    const ZONE = enum(u4) {
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
};

test "thermalinfo test" {
    try testing.expect(ThermalInfo.ZONE.zero.getValue() == 0);
}
