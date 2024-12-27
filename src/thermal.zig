const std = @import("std");
const testing = std.testing;

const thermal_file = "/sys/class/thermal/thermal_zone{}/temp";

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

const ThermalInfo = struct {
    zone0: ?f32 = null,
    zone1: ?f32 = null,
    zone2: ?f32 = null,
    zone3: ?f32 = null,
    zone4: ?f32 = null,
    zone5: ?f32 = null,
    zone6: ?f32 = null,
    zone7: ?f32 = null,
    zone8: ?f32 = null,

    fn setZone(self: *ThermalInfo, index: usize, value: f32) !void {
        switch (index) {
            0 => self.zone0 = value,
            1 => self.zone1 = value,
            2 => self.zone2 = value,
            3 => self.zone3 = value,
            4 => self.zone4 = value,
            5 => self.zone5 = value,
            6 => self.zone6 = value,
            7 => self.zone7 = value,
            8 => self.zone8 = value,
            else => return error.ThermalZoneNotAvailable,
        }
    }
};

pub fn info() !ThermalInfo {
    var thermalinfo = ThermalInfo{};
    for (0..8) |i| {
        const file_path = try std.fmt.allocPrint(std.heap.page_allocator, thermal_file, .{i});

        const file = std.fs.openFileAbsolute(file_path, .{}) catch {
            break;
        };

        var buffer: [5]u8 = undefined;
        const bytes_read = try file.readAll(&buffer);

        const temperature = try std.fmt.parseInt(i32, buffer[0..bytes_read], 10);
        const temp_celsius: f32 = @as(f32, @floatFromInt(temperature)) / 1000.0;
        try thermalinfo.setZone(i, temp_celsius);
    }
    return thermalinfo;
}

pub fn getTemperatureFromZone(zone: ZONE) !f32 {
    const file_path = try std.fmt.allocPrint(std.heap.page_allocator, thermal_file, .{zone.getValue()});
    const file = std.fs.openFileAbsolute(file_path, .{}) catch {
        return error.ZoneNotAvailable;
    };

    var buffer: [5]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);

    const temperature = try std.fmt.parseInt(i32, buffer[0..bytes_read], 10);
    const temp_celsius: f32 = @as(f32, @floatFromInt(temperature)) / 1000.0;
    return temp_celsius;
}

test "thermal" {
    try testing.expect(ZONE.zero.getValue() == 0);

    const thermalinfo = try info();
    try testing.expect(thermalinfo.zone0 != null);

    const temp_from_zone = try getTemperatureFromZone(ZONE.two);
    try testing.expect(temp_from_zone > 0.0);

    try testing.expectError(error.ZoneNotAvailable, getTemperatureFromZone(ZONE.eight));
}
