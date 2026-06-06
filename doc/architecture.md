# Architecture

## Design Goals

`audio_monitor` is intentionally narrow in scope:

- live input monitoring only
- no recording
- no metering
- no historical audio storage

## Dart Layer

The public Flutter API is exposed through:

- `AudioMonitor`
- strongly typed models
- `MethodChannel` commands

No `EventChannel` is used because the current plugin behavior is request/response oriented.

## Native macOS Layer

The macOS backend uses:

- Swift
- CoreAudio
- AudioUnit / HAL-based capture and playback

Current signal path:

`selected input -> native monitor pipeline -> system default output`

## Resource Handling

The native implementation:

- allocates only the buffers required for real-time processing
- avoids retaining raw historical audio
- clears the ring buffer when muted
- disposes audio units on stop and deinit

## Known Limitation

Direct selected-output routing on macOS is the hardest unresolved part of the backend.

The current implementation keeps the code organized so that richer output routing can be added later.
