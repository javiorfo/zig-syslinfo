const std = @import("std");
const testing = std.testing;

/// The path to the thermal zone temperature files.
const thermal_file = "/sys/class/thermal/thermal_zone{}/temp";

/// Represents the available thermal zones.
pub const ZONE = enum(u4) {
    /// Thermal zone 0.
    zero,
    /// Thermal zone 1.
    one,
    /// Thermal zone 2.
    two,
    /// Thermal zone 3.
    three,
    /// Thermal zone 4.
    four,
    /// Thermal zone 5.
    five,
    /// Thermal zone 6.
    six,
    /// Thermal zone 7.
    seven,
    /// Thermal zone 8.
    eight,

    /// Retrieves the integer value of the thermal zone.
    pub fn getValue(self: ZONE) u4 {
        return @intFromEnum(self);
    }

    /// Retrieves the thermal zone enum from the given integer value.
    pub fn getEnum(value: u4) ZONE {
        return @enumFromInt(value);
    }
};

/// Represents the thermal information for all available zones.
const ThermalInfo = struct {
    /// The temperature of thermal zone 0.
    zone0: ?f32 = null,
    /// The temperature of thermal zone 1.
    zone1: ?f32 = null,
    /// The temperature of thermal zone 2.
    zone2: ?f32 = null,
    /// The temperature of thermal zone 3.
    zone3: ?f32 = null,
    /// The temperature of thermal zone 4.
    zone4: ?f32 = null,
    /// The temperature of thermal zone 5.
    zone5: ?f32 = null,
    /// The temperature of thermal zone 6.
    zone6: ?f32 = null,
    /// The temperature of thermal zone 7.
    zone7: ?f32 = null,
    /// The temperature of thermal zone 8.
    zone8: ?f32 = null,

    /// Sets the temperature of the specified thermal zone.
    ///
    /// - `index`: The index of the thermal zone to set.
    /// - `value`: The temperature value to set.
    ///
    /// Returns an error if the specified thermal zone is not available.
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

/// Retrieves the current thermal information for all available zones.
///
/// Returns a `ThermalInfo` struct containing the temperature values for each available thermal zone.
pub fn info() !ThermalInfo {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak cpu info");
    const allocator = gpa.allocator();

    var thermalinfo = ThermalInfo{};
    for (0..8) |i| {
        const file_path = try std.fmt.allocPrint(allocator, thermal_file, .{i});
        defer allocator.free(file_path);

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

/// Retrieves the temperature value for the specified thermal zone.
///
/// - `id`: The ID of the thermal zone to retrieve the temperature for.
///
/// Returns the temperature value for the specified thermal zone, or an error if the zone is not available.
pub fn getTemperatureFromZoneId(id: u4) !f32 {
    return getTemperatureFromZone(ZONE.getEnum(id));
}

/// Retrieves the temperature value for the specified thermal zone.
///
/// - `zone`: The thermal zone to retrieve the temperature for.
///
/// Returns the temperature value for the specified thermal zone, or an error if the zone is not available.
pub fn getTemperatureFromZone(zone: ZONE) !f32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak cpu temperature from zone");
    const allocator = gpa.allocator();

    const file_path = try std.fmt.allocPrint(allocator, thermal_file, .{zone.getValue()});
    defer allocator.free(file_path);
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
    try testing.expect(ZONE.getEnum(1) == ZONE.one);

    const thermalinfo = try info();
    try testing.expect(thermalinfo.zone0 != null);

    const temp_from_zone = try getTemperatureFromZone(ZONE.two);
    try testing.expect(temp_from_zone > 0.0);

    const temp_from_zone_id = try getTemperatureFromZoneId(0);
    try testing.expect(temp_from_zone_id > 0.0);

    try testing.expectError(error.ZoneNotAvailable, getTemperatureFromZone(ZONE.eight));
}
