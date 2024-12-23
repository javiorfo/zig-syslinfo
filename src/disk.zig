const std = @import("std");
const testing = std.testing;
const c = @cImport({
    @cInclude("sys/statvfs.h");
});

pub const DiskInfo = struct {
    blocks: usize = 0,
    free: usize = 0,
    files: usize = 0,
    files_free: usize = 0,

    pub fn new(path: [*:0]const u8) !DiskInfo {
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

    pub fn percentageUsed(self: DiskInfo) !u8 {
        if (self.blocks == 0 or self.free == 0) {
            return error.DiskInfoUninitialized;
        }
        const used_blocks = self.blocks - self.free;
        const used_disk_percentage: u8 = @intFromFloat((@as(f32, @floatFromInt(used_blocks)) / @as(f32, @floatFromInt(self.blocks))) * @as(f32, 100.0));
        return used_disk_percentage;
    }
};

test "diskinfo test" {
    const diskinfo = try DiskInfo.new("/");
    try testing.expect(diskinfo.blocks != 0);
    try testing.expect(diskinfo.free != 0);
    try testing.expect(diskinfo.files != 0);
    try testing.expect(diskinfo.files_free != 0);
    try testing.expect(try diskinfo.percentageUsed() <= 100);

    try testing.expectError(error.StatVFSFailed, DiskInfo.new("/nonexistentvolume"));

    // This is a badly initialization example
    const diskinfo2 = DiskInfo{};
    try testing.expectError(error.DiskInfoUninitialized, diskinfo2.percentageUsed());
}
