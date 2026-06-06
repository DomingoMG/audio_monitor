# audio_monitor

`audio_monitor` is a Flutter desktop plugin for live audio input monitoring.

It lets a Flutter app select an input device and monitor that input through an output device in real time.

Example flow:

`Microphone / Line In / Audio Interface Input -> Headphones / Speakers / Output Device`

## What This Plugin Does

- Lists available input audio devices.
- Lists available output audio devices.
- Starts live input monitoring.
- Stops live input monitoring.
- Mutes and unmutes the live monitor without tearing down the session.
- Adjusts a dedicated monitor playback volume for the live monitor path.
- Exposes the current monitoring state.

## What This Plugin Does Not Do

- It is not an audio meter.
- It does not record audio.
- It does not store audio.
- It does not write audio files.
- It does not provide FFT, waveform, RMS, or peak analysis.
- It does not replace `system_audio_meter`.

## Platform Support

| Platform | Device listing | Input monitoring | Output selection |
| --- | --- | --- | --- |
| macOS | Implemented | Implemented | Partial |
| Windows | Planned | Planned | Planned |
| Linux | Not supported yet | Not supported yet | Not supported yet |

macOS notes:

- The current macOS implementation targets `selected input -> system default output`.
- Real-world latency still depends on the selected hardware, driver buffer sizes, and microphone permissions.

Windows notes:

- Windows is intentionally a placeholder for now.
- The planned backend will target the native Windows listen-to-device monitoring behavior where possible.

## Installation

Add the plugin to `pubspec.yaml`:

```yaml
dependencies:
  audio_monitor:
    path: ../audio_monitor
```

Then run:

```bash
flutter pub get
```

## Basic Usage

```dart
import 'package:audio_monitor/audio_monitor.dart';

final monitor = AudioMonitor();

final inputs = await monitor.getInputDevices();
final outputs = await monitor.getOutputDevices();

await monitor.start(
  inputDeviceId: inputs.first.id,
  outputDeviceId: outputs.first.id,
);

final active = await monitor.isMonitoring();
final state = await monitor.getState();

await monitor.mute();
await monitor.unmute();
await monitor.setVolume(0.5);

await monitor.stop();
```

`setVolume()` can also be called before `start()`, so the monitor begins with the desired playback level.

## Public API

### `AudioMonitorDevice`

- `id`
- `name`
- `isDefault`
- `type`

### `AudioMonitorState`

- `isMonitoring`
- `isMuted`
- `volume`
- `inputDeviceId`
- `outputDeviceId`

### Errors

Native failures are surfaced as `AudioMonitorException` with one of these codes:

- `deviceNotFound`
- `permissionDenied`
- `monitoringAlreadyActive`
- `monitoringNotActive`
- `platformNotSupported`
- `nativeAudioError`

## macOS Permissions

The macOS host app must include:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Audio Monitor needs microphone access to route the selected input device to your speakers or headphones in real time.</string>
```

The example app already includes this entry in:

- `example/macos/Runner/Info.plist`

If the macOS app is sandboxed, it must also include the microphone entitlement:

```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

## Limitations

- The plugin is focused only on live monitoring and routing.
- Near-zero latency is not physically possible, but the backend is tuned for low-latency live monitoring.
- End-to-end latency still depends on the audio devices and macOS buffer configuration.
- To hear monitoring through a specific speaker or headphones on macOS, set that device as the system default output first.
- Windows and Linux are not implemented in this release.

## Roadmap

- Add direct selected-output routing on macOS beyond the current default-output path.
- Add explicit resource disposal ergonomics if the API grows.
- Implement a Windows backend around native listen-to-device behavior.
- Evaluate Linux support later without widening scope prematurely.

## Documentation

- GitHub Pages docs source lives in `doc/`
- Release notes live in `CHANGELOG.md`
