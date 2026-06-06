# API

## Main Class

```dart
final monitor = AudioMonitor();
```

## Device Queries

```dart
final inputs = await monitor.getInputDevices();
final outputs = await monitor.getOutputDevices();
```

## Start And Stop

```dart
await monitor.start(
  inputDeviceId: input.id,
  outputDeviceId: output.id,
);

await monitor.stop();
```

## Mute Control

```dart
await monitor.mute();
await monitor.unmute();

final muted = await monitor.isMuted();
```

## Volume Control

```dart
await monitor.setVolume(0.5);
final volume = await monitor.getVolume();
```

`setVolume()` accepts values between `0.0` and `1.0`.

The configured volume can be set before `start()`, and that value will be used when monitoring begins.

## State

```dart
final state = await monitor.getState();
```

`AudioMonitorState` includes:

- `isMonitoring`
- `isMuted`
- `volume`
- `inputDeviceId`
- `outputDeviceId`

## Errors

Native failures are surfaced as `AudioMonitorException`.

Available error codes:

- `deviceNotFound`
- `permissionDenied`
- `monitoringAlreadyActive`
- `monitoringNotActive`
- `platformNotSupported`
- `nativeAudioError`
