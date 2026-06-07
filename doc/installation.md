# Installation

Add the dependency:

```yaml
dependencies:
  audio_monitor:
    path: ../audio_monitor
```

Install packages:

```bash
flutter pub get
```

## Windows notes

The Windows backend controls the operating system native `Listen to this device` setting for capture endpoints.

It does not create a custom capture or playback pipeline.

## Quick verification

```dart
final inputs = await AudioMonitor.getInputDevices();
final outputs = await AudioMonitor.getOutputDevices();

await AudioMonitor.enableNativeListen(
  inputDeviceId: inputs.first.id,
  outputDeviceId: outputs.first.id,
);
```

After enabling it, open Sound Control Panel and confirm the microphone `Listen` tab reflects the same state.
