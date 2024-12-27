const std = @import("std");

pub const cpu = @import("cpu.zig");
pub const disk = @import("disk.zig");
pub const memory = @import("memory.zig");
pub const network = @import("network.zig");
pub const thermal = @import("thermal.zig");
pub const volume = @import("volume.zig");

test {
    std.testing.refAllDecls(@This());
}
