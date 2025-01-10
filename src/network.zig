const std = @import("std");
const c = @cImport({
    @cInclude("NetworkManager.h");
    @cInclude("glib.h");
});

/// Represents the different types of network connections.
const ConnectionType = enum(u8) {
    /// Wi-Fi connection.
    wifi,
    /// Ethernet connection.
    ethernet,
    /// Unknown connection type.
    unknown,
};

/// Represents the current network connection state.
const State = struct {
    /// The connection speed in Mbps.
    connection_speed: f32 = 0.0,
    /// The type of network connection.
    connection_type: ConnectionType = .unknown,
    /// The signal strength of the connection (0-100).
    signal_strength: u8 = 0,
    /// The Service Set Identifier (SSID) of the network.
    SSID: [63]u8 = .{0} ** 63,
    /// The length of the SSID.
    SSID_len: u8 = 0,
    /// The IPv4 address of the connection.
    ipv4: [15]u8 = .{0} ** 15,
    /// The length of the IPv4 address.
    ipv4_len: u8 = 0,
    /// The subnet mask of the connection.
    mask: u8 = 0,
};

/// Retrieves the current network connection state.
///
/// Returns an optional `State` struct, or an error if the connection to the network manager fails.
pub fn state() !?State {
    var err: [*c]c.GError = 0x0;
    const client = c.nm_client_new(0x0, &err);
    if (client == null) {
        std.log.err("Connection Error {d} | {s}", .{ err.*.code, err.*.message });
        c.g_error_free(err);
        return error.CantConnectToNetworkManager;
    }
    defer c.g_object_unref(client);

    const devices = c.nm_client_get_devices(client);

    var i: usize = 0;
    while (i < devices.*.len) : (i += 1) {
        const device: *c.NMDevice = @ptrCast(devices.*.pdata[i]);
        const active_connection = c.nm_device_get_active_connection(device);
        if (active_connection != null) {
            var result = State{};

            const device_type = c.nm_device_get_device_type(device);

            const ipv4_config = c.nm_device_get_ip4_config(device);
            const ip_arr = c.nm_ip_config_get_addresses(ipv4_config);
            const ip_address: *c.NMIPAddress = @ptrCast(ip_arr.*.pdata[0]);
            const mask_prefix = c.nm_ip_address_get_prefix(ip_address);
            const address = c.nm_ip_address_get_address(ip_address);
            const address_len = std.mem.len(address);

            result.mask = @intCast(mask_prefix);
            @memcpy(result.ipv4[0..address_len], address[0..address_len]);
            result.ipv4_len = @intCast(address_len);

            if (device_type == c.NM_DEVICE_TYPE_ETHERNET) {
                const ethernet_device: ?*c.NMDeviceEthernet = @ptrCast(device);
                const speed_mbs = c.nm_device_ethernet_get_speed(ethernet_device);

                result.connection_type = .ethernet;
                result.connection_speed = @floatFromInt(speed_mbs);

                return result;
            } else if (device_type == c.NM_DEVICE_TYPE_WIFI) {
                const wifi_device: ?*c.NMDeviceWifi = @ptrCast(device);
                const access_point = c.nm_device_wifi_get_active_access_point(wifi_device);
                const ssid = c.nm_access_point_get_ssid(access_point);
                const ssid_utf8 = c.nm_utils_ssid_to_utf8(@as([*c]const c.guint8, @ptrCast(c.g_bytes_get_data(ssid, 0x0))), c.g_bytes_get_size(ssid));
                const ssid_utf8_len = std.mem.len(ssid_utf8);
                const signal_strength = c.nm_access_point_get_strength(access_point);
                const max_bitrate = c.nm_access_point_get_max_bitrate(access_point);

                result.connection_type = .wifi;
                result.connection_speed = (@as(f32, @floatFromInt(signal_strength)) / 100.0) * @as(f32, @floatFromInt(max_bitrate / 1000));
                result.signal_strength = @intCast(signal_strength);
                @memcpy(result.SSID[0..ssid_utf8_len], ssid_utf8[0..ssid_utf8_len]);
                result.SSID_len = @intCast(ssid_utf8_len);

                return result;
            }
        }
    }
    return null;
}
