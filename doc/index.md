# audio_monitor

`audio_monitor` is a Flutter desktop plugin for live audio input monitoring.

It is designed for desktop apps that need to route a selected audio input to an output in real time.

Example flow:

`Microphone / Line In / Audio Interface Input -> Headphones / Speakers / Output`

## What It Does

- Lists available input devices.
- Lists available output devices.
- Starts and stops live monitoring.
- Mutes and unmutes the monitoring path.
- Applies a dedicated monitor volume.
- Exposes the current monitoring state to Flutter.

## What It Does Not Do

- No recording
- No file writing
- No FFT
- No waveform generation
- No RMS or peak metering
- No audio history persistence

## Platform Status

| Platform | Device listing | Monitoring | Output selection |
| --- | --- | --- | --- |
| macOS | Implemented | Implemented | Partial |
| Windows | Planned | Planned | Planned |
| Linux | Not supported yet | Not supported yet | Not supported yet |

## macOS Notes

- The current macOS backend targets `selected input -> system default output`.
- To hear the monitor through a specific device, set that device as the system default output first.
- The monitor volume is independent from the app API, but still depends on the device and macOS audio path.

## Next Steps

- Read the [installation guide](installation.md)
- See the [API guide](api.md)
- Review the [roadmap](roadmap.md)
