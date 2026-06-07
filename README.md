# audio_monitor

A Flutter desktop plugin for controlling native audio monitoring features.

## Windows native listen support

On Windows, `audio_monitor` configures the built-in operating system feature exposed in Sound Control Panel as:

`Recording > Microphone Properties > Listen > Listen to this device`

This implementation:

- Uses the Windows endpoint property store for the capture device
- Reads and writes the same native setting shown by the Sound Control Panel
- Can assign a specific playback endpoint or the current default playback device

This implementation does **not**:

- Capture audio in the plugin
- Render audio in the plugin
- Build a custom software monitoring pipeline
- Record, buffer, or process PCM samples

Behavior depends on Windows endpoint property support and write access to the device property store.

## Platform support

| Platform | Status | Notes |
| --- | --- | --- |
| Windows | Supported | Controls native `Listen to this device` |
| macOS | Unsupported for this API | Throws `unsupportedPlatform` |
| Linux | Unsupported for this API | Throws `unsupportedPlatform` |

## Installation

```yaml
dependencies:
  audio_monitor:
    path: ../audio_monitor
```

Then run:

```bash
flutter pub get
```

## Dart API

```dart
import 'package:audio_monitor/audio_monitor.dart';

final inputs = await AudioMonitor.getInputDevices();
final outputs = await AudioMonitor.getOutputDevices();

final configuration = await AudioMonitor.getNativeListenConfiguration(
  inputDeviceId: inputs.first.id,
);

await AudioMonitor.enableNativeListen(
  inputDeviceId: inputs.first.id,
  outputDeviceId: outputs.first.id,
);

await AudioMonitor.setNativeListenOutputDevice(
  inputDeviceId: inputs.first.id,
  outputDeviceId: AudioMonitor.defaultOutputDeviceId,
);

await AudioMonitor.disableNativeListen(
  inputDeviceId: inputs.first.id,
);
```

## Data models

### `AudioInputDevice`

- `id`
- `name`
- `isDefault`
- `state`

### `AudioOutputDevice`

- `id`
- `name`
- `isDefault`
- `state`

### `AudioDeviceState`

- `active`
- `disabled`
- `unplugged`
- `notPresent`
- `unknown`

### `NativeListenConfiguration`

- `enabled`
- `outputDeviceId`
- `outputDeviceName`
- `usesDefaultOutputDevice`

## Errors

Native failures are surfaced as `AudioMonitorException` with these codes:

- `inputDeviceNotFound`
- `outputDeviceNotFound`
- `deviceNotActive`
- `listenConfigurationUnavailable`
- `listenConfigurationUnsupported`
- `permissionDenied`
- `nativeWindowsApiFailed`
- `unsupportedPlatform`

## Native Windows Listen to this device

The Windows backend writes endpoint properties associated with native microphone monitoring. The goal is that after calling `enableNativeListen`, the Sound Control Panel reflects the same state.

If your device driver or Windows build refuses property-store writes for this setting, the plugin returns a platform exception instead of falling back to a custom audio monitor path.

## Diagnostic tool

The repository includes a Windows diagnostic executable target:

- `audio_monitor_property_dump`

It dumps property keys and values for capture and render endpoints so you can compare endpoint state before and after changing `Listen to this device` manually in Windows.

## Manual QA checklist

1. Run the example app on Windows.
2. Verify that input devices are listed with state and default marker.
3. Verify that output devices are listed with state and default marker.
4. Select an input device and an output device.
5. Press `Enable native listen`.
6. Open Sound Control Panel and confirm `Listen to this device` is checked.
7. Confirm the selected playback device matches the app state.
8. Change the output device in the app and press `Apply output device`.
9. Reopen the microphone `Listen` tab and confirm the playback target changed.
10. Press `Disable native listen`.
11. Confirm the checkbox is unchecked in Sound Control Panel.

## Warning

This feature is Windows-specific and depends on native endpoint property behavior. It does not provide a portable cross-platform software monitor path.
