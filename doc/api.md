# API

## Device Queries

```dart
final inputs = await AudioMonitor.getInputDevices();
final outputs = await AudioMonitor.getOutputDevices();
```

## Native Listen Configuration

```dart
final configuration = await AudioMonitor.getNativeListenConfiguration(
  inputDeviceId: input.id,
);
```

## Enable And Disable

```dart
await AudioMonitor.enableNativeListen(
  inputDeviceId: input.id,
  outputDeviceId: output.id,
);

await AudioMonitor.disableNativeListen(
  inputDeviceId: input.id,
);
```

## Change Output Device

```dart
await AudioMonitor.setNativeListenOutputDevice(
  inputDeviceId: input.id,
  outputDeviceId: AudioMonitor.defaultOutputDeviceId,
);
```

`AudioMonitor.defaultOutputDeviceId` tells Windows to use the current default playback device when the endpoint property store accepts that mode.

## Data Models

`AudioInputDevice` and `AudioOutputDevice` include:

- `id`
- `name`
- `isDefault`
- `state`

`NativeListenConfiguration` includes:

- `enabled`
- `outputDeviceId`
- `outputDeviceName`
- `usesDefaultOutputDevice`
