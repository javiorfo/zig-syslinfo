const std = @import("std");

const stat_file = "/proc/stat";
const cpu_file = "/proc/cpuinfo";
const update_interval = 100 * std.time.ns_per_ms;

const CpuInfo = struct {
    vendor_id: []const u8 = "",
    cpu_family: u8 = 0,
    model: u32 = 0,
    model_name: []const u8 = "",
    microcode: []const u8 = "",
    cache_size: []const u8 = "",
    cpu_cores: u8 = 0,
};

pub fn info() !CpuInfo {
    const file = try std.fs.openFileAbsolute(cpu_file, .{});
    defer file.close();

    const reader = file.reader();
    var buffer: [1024]u8 = undefined;
    var cpuinfo = CpuInfo{};
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        try setValue([]const u8, &cpuinfo.vendor_id, line, "vendor_id");
        try setValue(u8, &cpuinfo.cpu_family, line, "cpu family");
        if (cpuinfo.model == 0) {
            try setValue(u32, &cpuinfo.model, line, "model");
        }
        try setValue([]const u8, &cpuinfo.model_name, line, "model name");
        try setValue([]const u8, &cpuinfo.microcode, line, "microcode");
        try setValue([]const u8, &cpuinfo.cache_size, line, "cache size");
        try setValue(u8, &cpuinfo.cpu_cores, line, "cpu cores");
        if (cpuinfo.cpu_cores != 0) {
            break;
        }
    }
    return cpuinfo;
}

fn setValue(comptime T: type, value: *T, line: []const u8, section: []const u8) !void {
    if (std.mem.startsWith(u8, line, section)) {
        const index = std.mem.indexOf(u8, line, ":").? + 2;
        value.* = switch (T) {
            u8, u16, u32 => try std.fmt.parseInt(T, line[index..], 10),
            f16, f32 => try std.fmt.parseFloat(T, line[index..]),
            else => try std.mem.Allocator.dupe(std.heap.page_allocator, u8, line[index..]),
        };
    }
}

pub fn percentageUsed() !f32 {
    const prev_stats = try usage();
    std.time.sleep(update_interval);
    const curr_stats = try usage();
    return calculateCpuUsage(prev_stats, curr_stats);
}

pub fn usage() !CpuUsage {
    const file = try std.fs.openFileAbsolute(stat_file, .{});
    defer file.close();

    var buffer: [256]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);
    const data = buffer[0..bytes_read];

    var lines = std.mem.splitSequence(u8, data, "\n");
    if (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "cpu ")) {
            var parts = std.mem.splitSequence(u8, line["cpu ".len + 1 ..], " ");
            return .{
                .user = try std.fmt.parseInt(u64, parts.next().?, 10),
                .nice = try std.fmt.parseInt(u64, parts.next().?, 10),
                .system = try std.fmt.parseInt(u64, parts.next().?, 10),
                .idle = try std.fmt.parseInt(u64, parts.next().?, 10),
                .iowait = try std.fmt.parseInt(u64, parts.next().?, 10),
            };
        }
    }
    return error.CpuUsageInvalidData;
}

const CpuUsage = struct {
    user: u64,
    nice: u64,
    system: u64,
    idle: u64,
    iowait: u64,

    fn getTotal(self: CpuUsage) u64 {
        return self.user + self.nice + self.system + self.idle + self.iowait;
    }
};

fn calculateCpuUsage(prev: CpuUsage, curr: CpuUsage) f32 {
    const prev_idle = prev.idle;
    const curr_idle = curr.idle;

    const prev_total: u64 = prev.getTotal();
    const curr_total: u64 = curr.getTotal();

    const total_diff = curr_total - prev_total;
    const idle_diff = curr_idle - prev_idle;
    const res: f32 = (1.0 - (@as(f32, @floatFromInt(idle_diff)) / @as(f32, @floatFromInt(total_diff)))) * 100.0;
    return res;
}

test "cpu" {
    const testing = std.testing;
    const cpu_usage = try usage();
    try testing.expect(cpu_usage.getTotal() > 0);
    try testing.expect(@TypeOf(try percentageUsed()) == f32);

    const cpuinfo = try info();
    try testing.expect(cpuinfo.vendor_id.len > 0);
    try testing.expect(cpuinfo.cpu_family > 0);
    try testing.expect(cpuinfo.model > 0);
    try testing.expect(cpuinfo.model_name.len > 0);
    try testing.expect(cpuinfo.microcode.len > 0);
    try testing.expect(cpuinfo.cache_size.len > 0);
    try testing.expect(cpuinfo.cpu_cores > 0);
}
