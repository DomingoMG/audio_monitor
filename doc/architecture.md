# Architecture

## Design Goals

`audio_monitor` is intentionally narrow in scope:

- native Windows listen control only
- no custom capture pipeline
- no custom playback pipeline
- no recording
- no metering
- no retained PCM buffers

## Dart Layer

The public Flutter API is exposed through:

- `AudioMonitor`
- strongly typed device and configuration models
- `MethodChannel` request and response calls

No `EventChannel` is used because the current feature set is configuration-oriented rather than stream-oriented.

## Native Windows Layer

The Windows backend uses:

- Core Audio endpoint enumeration through `IMMDeviceEnumerator`
- endpoint metadata through `IMMDevice`, `IMMDeviceCollection`, and `IPropertyStore`
- endpoint state values from `DEVICE_STATE_*`
- native endpoint properties associated with `Listen to this device`

The backend reads and writes endpoint properties for:

- whether native listen is enabled
- which render endpoint Windows should use for playback

## Configuration Model

The plugin does not move audio itself.

Instead, it:

1. enumerates capture and render endpoints
2. resolves the selected endpoint ids
3. reads or writes the relevant endpoint properties
4. lets Windows own the actual audio path

## Diagnostics

The repository includes `audio_monitor_property_dump` for inspecting endpoint property values during development and troubleshooting.

This is especially useful when validating behavior across different device drivers or Windows builds.

## Known Limitation

This feature depends on native Windows endpoint property behavior. Some drivers or system configurations may refuse property-store writes or expose different behavior than the Sound Control Panel UI suggests.
