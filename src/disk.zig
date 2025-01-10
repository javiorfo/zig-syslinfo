const std = @import("std");
const testing = std.testing;
const c = @cImport({
    @cInclude("sys/statvfs.h");
});

/// Retrieves the current disk usage statistics for the specified path.
///
/// - `path`: The path to the file system to retrieve the usage statistics for.
///
/// Returns a `DiskUsage` struct containing the disk usage statistics, or an error if the `statvfs` system call fails.
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

/// Represents the current disk usage statistics.
const DiskUsage = struct {
    /// The total number of blocks on the file system.
    blocks: usize = 0,
    /// The number of free blocks on the file system.
    free: usize = 0,
    /// The total number of inodes (files) on the file system.
    files: usize = 0,
    /// The number of free inodes (files) on the file system.
    files_free: usize = 0,

    /// Calculates the percentage of disk space used.
    ///
    /// Returns the percentage of disk space used as a `f32` value, or an error if the disk usage statistics are not initialized.
    pub fn percentageUsed(self: DiskUsage) !f32 {
        if (self.blocks == 0 or self.free == 0) {
            return error.DiskUsageUninitialized;
        }
        const used_blocks = self.blocks - self.free;
        const used_disk_percentage: f32 = (@as(f32, @floatFromInt(used_blocks)) / @as(f32, @floatFromInt(self.blocks))) * 100.0;
        return used_disk_percentage;
    }
};

test "disk" {
    const disk_usage = try usage("/");
    try testing.expect(disk_usage.blocks != 0);
    try testing.expect(disk_usage.free != 0);
    try testing.expect(disk_usage.files != 0);
    try testing.expect(disk_usage.files_free != 0);
    try testing.expect(try disk_usage.percentageUsed() <= 100.0);

    try testing.expectError(error.StatVFSFailed, usage("/nonexistentvolume"));

    // This is a badly initialization example
    const disk_usage2 = DiskUsage{};
    try testing.expectError(error.DiskUsageUninitialized, disk_usage2.percentageUsed());
}
