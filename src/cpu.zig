const std = @import("std");

const stat_file = "/proc/stat";
const cpu_file = "/proc/cpuinfo";

pub const CpuInfo = struct {
    vendor_id: []const u8,
    cpu_family: u8,
    model: u32,
    model_name: []const u8,
    microcode: []const u8,
    cache_size: u32,
    cpu_cores: u8,

    pub fn new() !void {
        const file = try std.fs.openFileAbsolute(cpu_file, .{});
        defer file.close();

        const reader = file.reader();
        var buffer: [1024]u8 = undefined;
        var cpu_info = CpuInfo{};
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            try setValue([]u8, &cpu_info.vendor_id, line, "vendor_id");

            if (std.mem.startsWith(u8, line, "vendor_id")) {
                const index = std.mem.indexOf(u8, line, ":");
                cpu_info.vendor_id = line[index.? + 2 ..];
            } else if (std.mem.startsWith(u8, line, "cpu family")) {
                const index = std.mem.indexOf(u8, line, ":");
                std.debug.print("cpu family: {s}\n", .{line[index.? + 2 ..]});
            } else if (std.mem.startsWith(u8, line, "model")) {
                const index = std.mem.indexOf(u8, line, ":");
                std.debug.print("model: {s}\n", .{line[index.? + 2 ..]});
            } else if (std.mem.startsWith(u8, line, "model name")) {
                const index = std.mem.indexOf(u8, line, ":");
                std.debug.print("model name: {s}\n", .{line[index.? + 2 ..]});
            } else if (std.mem.startsWith(u8, line, "microcode")) {
                const index = std.mem.indexOf(u8, line, ":");
                std.debug.print("microcode: {s}\n", .{line[index.? + 2 ..]});
            } else if (std.mem.startsWith(u8, line, "cache size")) {
                const index = std.mem.indexOf(u8, line, ":");
                std.debug.print("cache size: {s}\n", .{line[index.? + 2 ..]});
            } else if (std.mem.startsWith(u8, line, "cpu cores")) {
                const index = std.mem.indexOf(u8, line, ":");
                std.debug.print("cpu cores: {s}\n", .{line[index.? + 2 ..]});
                break;
            }
        }
    }

    fn setValue(comptime T: type, value: *T, line: []const u8, section: []const u8) !void {
        if (std.mem.startsWith(u8, line, section)) {
            const index = std.mem.indexOf(u8, line, ":").? + 2;
            value.* = switch (T) {
                u8, u16, u32 => try std.fmt.parseInt(T, line[index..], 10),
                f16, f32 => try std.fmt.parseFloat(T, line[index..]),
                else => line[index..],
            };
        }
    }

    fn countCores() !u8 {
        const file = try std.fs.openFileAbsolute(stat_file, .{});
        defer file.close();

        var buffer: [4096]u8 = undefined;
        const bytes_read = try file.readAll(&buffer);
        const data = buffer[0..bytes_read];

        var lines = std.mem.splitSequence(u8, data, "\n");
        var core_count: u8 = 0;

        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "cpu") and line.len > 3 and line[3] >= '0' and line[3] <= '9') {
                core_count += 1;
            }
        }

        return core_count;
    }
};

pub const CpuUsage = struct {
    const update_interval = 100 * std.time.ns_per_ms;

    pub fn percentageUsed() !f32 {
        const prev_stats = try readCpuStats();
        std.time.sleep(update_interval);
        const curr_stats = try readCpuStats();

        const cpu_usage = calculateCpuUsage(prev_stats, curr_stats);
        return cpu_usage;
    }

    fn readCpuStats() ![5]u64 {
        const file = try std.fs.openFileAbsolute(stat_file, .{});
        defer file.close();

        var buffer: [256]u8 = undefined;
        const bytes_read = try file.readAll(&buffer);
        const data = buffer[0..bytes_read];

        var lines = std.mem.splitSequence(u8, data, "\n");
        if (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "cpu ")) {
                var parts = std.mem.splitSequence(u8, line["cpu ".len + 1 ..], " ");
                var cpu_times: [5]u64 = undefined;
                var i: usize = 0;
                while (parts.next()) |value| : (i += 1) {
                    if (i > 4) break;
                    cpu_times[i] = try std.fmt.parseInt(u64, value, 10);
                }
                return cpu_times;
            }
        }
        return error.CpuUsageInvalidData;
    }

    fn calculateCpuUsage(prev: [5]u64, curr: [5]u64) f32 {
        const prev_idle = prev[3];
        const curr_idle = curr[3];

        const prev_total: u64 = prev[0] + prev[1] + prev[2] + prev[3] + prev[4];
        const curr_total: u64 = curr[0] + curr[1] + curr[2] + curr[3] + curr[4];

        const total_diff = curr_total - prev_total;
        const idle_diff = curr_idle - prev_idle;
        const res: f32 = (1.0 - (@as(f32, @floatFromInt(idle_diff)) / @as(f32, @floatFromInt(total_diff)))) * 100.0;
        return res;
    }
};

test "cpuinfo test" {}
