const std = @import("std");
const testing = std.testing;

pub const MemInfo = struct {
    total: usize = 0,
    free: usize = 0,
    available: usize = 0,
    cached: usize = 0,
    buffers: usize = 0,
    total_swap: usize = 0,
    free_swap: usize = 0,

    pub fn new() !MemInfo {
        const file = try std.fs.openFileAbsolute("/proc/meminfo", .{});
        defer file.close();

        var buffer: [1024]u8 = undefined;
        const bytes_read = try file.readAll(&buffer);

        const contents = buffer[0..bytes_read];

        var lines = std.mem.split(u8, contents, "\n");
        var meminfo = MemInfo{};
        while (lines.next()) |line| {
            try setValue(&meminfo.total, line, "MemTotal:");
            try setValue(&meminfo.free, line, "MemFree:");
            try setValue(&meminfo.available, line, "MemAvailable:");
            try setValue(&meminfo.cached, line, "Cached:");
            try setValue(&meminfo.buffers, line, "Buffers:");
            try setValue(&meminfo.total_swap, line, "SwapTotal:");
            try setValue(&meminfo.free_swap, line, "SwapFree:");
        }

        return meminfo;
    }

    pub fn percentageUsed(self: MemInfo) !u8 {
        if (self.total == 0 or self.free == 0) {
            return error.MemInfoZeroedError;
        }
        const used_mem = self.total - self.free - self.buffers - self.cached;
        const used_ram_perc: u8 = @intFromFloat((@as(f32, @floatFromInt(used_mem)) / @as(f32, @floatFromInt(self.total))) * @as(f32, 100.0));
        return used_ram_perc;
    }

    fn setValue(value: *usize, line: []const u8, section: []const u8) !void {
        if (std.mem.startsWith(u8, line, section)) {
            value.* = try std.fmt.parseInt(usize, std.mem.trim(u8, line[section.len..], " kB"), 10);
        }
    }
};

test "meminfo test" {
    const meminfo = try MemInfo.new();
    try testing.expect(meminfo.total != 0);
    try testing.expect(meminfo.free != 0);
    try testing.expect(meminfo.available != 0);
    try testing.expect(meminfo.cached != 0);
    try testing.expect(meminfo.buffers != 0);
    try testing.expect(meminfo.total_swap != 0);
    try testing.expect(meminfo.free_swap != 0);
    try testing.expect(try meminfo.percentageUsed() <= 100);

    const meminfo2 = MemInfo{};
    try testing.expectError(error.MemInfoZeroedError, meminfo2.percentageUsed());
}
