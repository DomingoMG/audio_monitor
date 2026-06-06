# Installation

## Add The Plugin

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

await monitor.setVolume(0.4);

await monitor.start(
  inputDeviceId: inputs.first.id,
  outputDeviceId: outputs.first.id,
);
```

## macOS Permissions

Host apps must include:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Audio Monitor needs microphone access to route the selected input device to your speakers or headphones in real time.</string>
```

If the app is sandboxed, also include:

```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

## Important macOS Behavior

- Monitoring currently routes to the system default output.
- Selecting another output in the Flutter UI does not bypass the current macOS limitation unless that output is also the default system output.

## Windows And Linux

- Windows is not implemented yet.
- Linux is intentionally unsupported for now.
