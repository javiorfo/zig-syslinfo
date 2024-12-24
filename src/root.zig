const std = @import("std");

pub const CpuInfo = @import("cpu.zig").CpuInfo;
pub const DiskInfo = @import("disk.zig").DiskInfo;
pub const MemInfo = @import("memory.zig").MemInfo;
pub const NetInfo = @import("network.zig").NetInfo;
pub const ThermalInfo = @import("thermal.zig").ThermalInfo;
pub const VolumeInfo = @import("volume.zig").VolumeInfo;

test {
    std.testing.refAllDecls(@This());
}
