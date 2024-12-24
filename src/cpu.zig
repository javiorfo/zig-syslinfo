const std = @import("std");

// TODO /proc/cpuinfo more info
pub const CpuInfo = struct {
    const stat_file = "/proc/stat";
    const update_interval = 100 * std.time.ns_per_ms;

    pub fn percentageUsed() !f32 {
        const prev_stats = try readCpuStats();
        std.time.sleep(update_interval);
        const curr_stats = try readCpuStats();

        const cpu_usage = calculateCpuUsage(prev_stats, curr_stats);
        return cpu_usage;
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
            } else {
                error.NoCpuDataFromFile;
            }
        }
        return error.InvalidData;
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
