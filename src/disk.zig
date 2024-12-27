const std = @import("std");
const testing = std.testing;
const c = @cImport({
    @cInclude("sys/statvfs.h");
});

pub fn usage(path: [*:0]const u8) !DiskUsage {
    var stat: c.struct_statvfs = undefined;
    if (c.statvfs(path, &stat) != 0) {
        return error.StatVFSFailed;
    }

    return .{
        .blocks = @as(usize, stat.f_blocks),
        .free = @as(usize, stat.f_bfree),
        .files = @as(usize, stat.f_files),
        .files_free = @as(usize, stat.f_ffree),
    };
}

const DiskUsage = struct {
    blocks: usize = 0,
    free: usize = 0,
    files: usize = 0,
    files_free: usize = 0,

    pub fn percentageUsed(self: DiskUsage) !u8 {
        if (self.blocks == 0 or self.free == 0) {
            return error.DiskUsageUninitialized;
        }
        const used_blocks = self.blocks - self.free;
        const used_disk_percentage: u8 = @intFromFloat((@as(f32, @floatFromInt(used_blocks)) / @as(f32, @floatFromInt(self.blocks))) * @as(f32, 100.0));
        return used_disk_percentage;
    }
};

test "disk" {
    const disk_usage = try usage("/");
    try testing.expect(disk_usage.blocks != 0);
    try testing.expect(disk_usage.free != 0);
    try testing.expect(disk_usage.files != 0);
    try testing.expect(disk_usage.files_free != 0);
    try testing.expect(try disk_usage.percentageUsed() <= 100);

    try testing.expectError(error.StatVFSFailed, usage("/nonexistentvolume"));

    // This is a badly initialization example
    const disk_usage2 = DiskUsage{};
    try testing.expectError(error.DiskUsageUninitialized, disk_usage2.percentageUsed());
}
