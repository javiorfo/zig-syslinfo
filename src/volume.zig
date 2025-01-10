const std = @import("std");
const c = @cImport({
    @cInclude("alsa/asoundlib.h");
});

/// Represents the current state of the sound system.
const State = struct {
    /// The current volume level (0-100).
    volume: u8 = 0,
    /// Whether the sound is muted or not.
    muted: bool = false,
    /// The minimum volume level.
    min: u64 = 0,
    /// The maximum volume level.
    max: u64 = 0,
    /// The name of the sound card.
    card_name: [:0]const u8,
};

/// Represents the configuration for a sound card.
const SoundCard = struct {
    /// The name of the sound card.
    name: [:0]const u8 = "default",
    /// The name of the sound control to use.
    salem: [:0]const u8 = "Master",
};

/// Retrieves the current state of the sound system.
///
/// - `card`: The configuration for the sound card to use.
///
/// Returns a `State` struct containing the current state of the sound system.
pub fn state(sound_card: SoundCard) !State {
    var handle: ?*c.snd_mixer_t = null;
    defer if (handle) |h| {
        _ = c.snd_mixer_detach(h, sound_card.name.ptr);
        _ = c.snd_mixer_close(h);
    };

    if (c.snd_mixer_open(&handle, 0) != 0) {
        return error.FailedToOpenMixer;
    }

    if (c.snd_mixer_attach(handle, sound_card.name.ptr) != 0) {
        return error.FailedToAttachMixer;
    }

    if (c.snd_mixer_selem_register(handle, 0x0, 0x0) != 0) {
        return error.FailedToRegisterMixer;
    }

    if (c.snd_mixer_load(handle) != 0) {
        return error.FailedToLoadMixer;
    }

    var sid: ?*c.snd_mixer_selem_id_t = null;
    _ = c.snd_mixer_selem_id_malloc(&sid);
    defer c.snd_mixer_selem_id_free(sid);

    c.snd_mixer_selem_id_set_index(sid, 0);
    c.snd_mixer_selem_id_set_name(sid, sound_card.salem.ptr);
    const elem = c.snd_mixer_find_selem(handle, sid);

    var vol_min: c_long = 0;
    var vol_max: c_long = 0;
    if (c.snd_mixer_selem_get_playback_volume_range(elem, &vol_min, &vol_max) != 0) {
        return error.CantReadVolumeRange;
    }

    _ = c.snd_mixer_handle_events(handle);

    var vol: c_long = 0;
    _ = c.snd_mixer_selem_get_playback_volume(elem, c.SND_MIXER_SCHN_MONO, &vol);
    var unmuted: c_int = 0;
    _ = c.snd_mixer_selem_get_playback_switch(elem, c.SND_MIXER_SCHN_MONO, &unmuted);

    const vol_resolution = vol_max - vol_min;

    const vol_normalized = @divTrunc((100 * (vol - vol_min)), vol_resolution);

    return .{
        .volume = @intCast(vol_normalized),
        .muted = unmuted == 0,
        .min = @intCast(vol_min),
        .max = @intCast(vol_max),
        .card_name = sound_card.name,
    };
}

test "volume" {
    const testing = std.testing;
    const s = try state(.{});
    try testing.expect(@TypeOf(s) == State);
    try testing.expect(s.volume > 0);
    try testing.expect(s.min == 0);
    try testing.expect(s.max > 0);
    try testing.expectEqual(s.card_name, "default");
}
