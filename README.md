# zig-syslinfo
*Linux sysinfo Zig library*

## Caveats
- C libs dependencies: `asound`, `libnm`, `glib-2.0` 
- Required Zig version: **0.13**
- This library has been developed on and for Linux following open source philosophy.

## Usage
```zig
const std = @import("std");
const syslinfo = @import("syslinfo");

pub fn main() !void {
    // DISK
    const disk = try syslinfo.disk.usage("/");
    std.debug.print("DISK free {d}\n", disk.free);
    std.debug.print("DISK blocks {d}\n", disk.blocks);
    std.debug.print("DISK files {d}\n", disk.files);
    std.debug.print("DISK files free {d}\n", disk.files_free);
    std.debug.print("DISK perc used {d:.2}%\n", try disk.percentageUsed());

    // CPU
    const cpu = syslinfo.cpu;
    const cpu_usage = try cpu.usage();
    std.debug.print("CPU user {d}\n", cpu_usage.user);
    std.debug.print("CPU nice {d}\n", cpu_usage.nice);
    std.debug.print("CPU idle {d}\n", cpu_usage.idle);
    std.debug.print("CPU system {d}\n", cpu_usage.system);
    std.debug.print("CPU iowait {d}\n", cpu_usage.iowait);

    const cpu_info = try cpu.info();
    std.debug.print("CPU vendor id {s}\n", cpu_info.vendor_id);
    std.debug.print("CPU model {d}\n", cpu_info.model);
    std.debug.print("CPU model name {s}\n", cpu_info.model_name);
    std.debug.print("CPU microcode {s}\n", cpu_info.microcode);
    std.debug.print("CPU cores {d}\n", cpu_info.cpu_cores);
    std.debug.print("CPU family {d}\n", cpu_info.cpu_family);
    std.debug.print("CPU cache size {s}\n", cpu_info.cache_size);
    std.debug.print("CPU perc used {d:.2}%\n", try cpu.percentageUsed());

    // THERMAL
    const thermal = syslinfo.thermal;
    const thermal_info = try thermal.info();
    std.debug.print("THERMAL zone0 {d}\n", thermal_info.zone0.?);
    std.debug.print("THERMAL zone1 {d}\n", try thermal.getTemperatureFromZone(thermal.ZONE.one));
    std.debug.print("THERMAL zone2 {d}\n", try thermal.getTemperatureFromZoneId(2));

    // MEMORY
    const memory = try syslinfo.memory.usage();
    std.debug.print("MEM free {d}\n", memory.free);
    std.debug.print("MEM total {d}\n", memory.total);
    std.debug.print("MEM cached {d}\n", memory.cached);
    std.debug.print("MEM buffers {d}\n", memory.buffers);
    std.debug.print("MEM available {d}\n", memory.available);
    std.debug.print("MEM free swap {d}\n", memory.free_swap);
    std.debug.print("MEM total swap {d}\n", memory.total_swap);
    std.debug.print("MEM perc used {d:.2}%\n", try memory.percentageUsed());

    // VOLUME
    const vol = try syslinfo.volume.state(.{}); // Receives a struct (default values are "default" and "Master")
    std.debug.print("VOL card name {s}\n", vol.card_name);
    std.debug.print("VOL volume {d}%\n", vol.volume);
    std.debug.print("VOL minimum {d}\n", vol.min);
    std.debug.print("VOL maximum {d}\n", vol.max);
    std.debug.print("VOL is muted {b}\n", vol.muted);

    // NETWORK
    const net = try syslinfo.network.state();
    std.debug.print("NET SSID {s}\n", net.?.SSID);
    std.debug.print("NET SSID len {d}\n", net.?.SSID_len);
    std.debug.print("NET IPv4 {s}\n", net.?.ipv4);
    std.debug.print("NET IPv4 len {d}\n", net.?.ipv4_len);
    std.debug.print("NET mask {d}\n", net.?.mask);
    std.debug.print("NET signal strength {d}\n", net.?.signal_strength);
    std.debug.print("NET connection speed {d}\n", net.?.connection_speed);
    std.debug.print("NET connection type {d}\n", net.?.connection_type);
}
```

## Installation
#### In your `build.zig.zon`:
```zig
.dependencies = .{
    .syslinfo = .{
        .url = "https://github.com/javiorfo/zig-syslinfo/archive/refs/heads/master.tar.gz",            
        .hash = "12201a1440e899e5e52cdbebab93eb49ed1a629ce38a81337fe3b9ff6343d4780637",
    },
}
```

#### In your `build.zig`:
```zig
const dep = b.dependency("syslinfo", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("syslinfo", dep.module("syslinfo"));

exe.linkLibC();
exe.linkSystemLibrary("asound");
exe.linkSystemLibrary("libnm");
exe.linkSystemLibrary("glib-2.0");
```

---

### Donate
- **Bitcoin** [(QR)](https://raw.githubusercontent.com/javiorfo/img/master/crypto/bitcoin.png)  `1GqdJ63RDPE4eJKujHi166FAyigvHu5R7v`
- [Paypal](https://www.paypal.com/donate/?hosted_button_id=FA7SGLSCT2H8G)
