const std = @import("std");
const testing = std.testing;

pub fn usage() !MemUsage {
    const file = try std.fs.openFileAbsolute("/proc/meminfo", .{});
    defer file.close();

    var buffer: [1024]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);

    const contents = buffer[0..bytes_read];

    var lines = std.mem.split(u8, contents, "\n");
    var meminfo = MemUsage{};
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

fn setValue(value: *usize, line: []const u8, section: []const u8) !void {
    if (std.mem.startsWith(u8, line, section)) {
        value.* = try std.fmt.parseInt(usize, std.mem.trim(u8, line[section.len..], " kB"), 10);
    }
}

const MemUsage = struct {
    total: usize = 0,
    free: usize = 0,
    available: usize = 0,
    cached: usize = 0,
    buffers: usize = 0,
    total_swap: usize = 0,
    free_swap: usize = 0,

    pub fn percentageUsed(self: MemUsage) !f32 {
        if (self.total == 0 or self.free == 0 or self.buffers == 0 or self.cached == 0) {
            return error.MemUsageUninitialized;
        }
        const used_mem = self.total - self.free - self.buffers - self.cached;
        const used_ram_percentage = (@as(f32, @floatFromInt(used_mem)) / @as(f32, @floatFromInt(self.total))) * @as(f32, 100.0);
        return used_ram_percentage;
    }
};

test "memory" {
    const mem_usage = try usage();
    try testing.expect(mem_usage.total != 0);
    try testing.expect(mem_usage.free != 0);
    try testing.expect(mem_usage.available != 0);
    try testing.expect(mem_usage.cached != 0);
    try testing.expect(mem_usage.buffers != 0);
    try testing.expect(mem_usage.total_swap != 0);
    try testing.expect(mem_usage.free_swap != 0);
    try testing.expect(try mem_usage.percentageUsed() <= 100.0);

    // This is a badly initialization example
    const mem_usage2 = MemUsage{};
    try testing.expectError(error.MemUsageUninitialized, mem_usage2.percentageUsed());
}
