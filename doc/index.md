# audio_monitor

`audio_monitor` is a Flutter desktop plugin for controlling native audio monitoring features.

The current Windows implementation targets the operating system feature exposed in Sound Control Panel as:

`Recording > Microphone Properties > Listen > Listen to this device`

It is intended for desktop apps that need to enable, disable, inspect, and configure the native Windows monitoring path for a capture device.

## What It Does

- Lists available input devices
- Lists available output devices
- Reads native Windows listen configuration
- Enables native `Listen to this device`
- Disables native `Listen to this device`
- Assigns a specific playback device or the default playback device

## What It Does Not Do

- No custom audio capture loop
- No custom audio render loop
- No PCM processing
- No recording
- No file writing
- No metering

## Platform Status

| Platform | Native listen control | Notes |
| --- | --- | --- |
| Windows | Implemented | Uses endpoint property store behavior |
| macOS | Not implemented for this API | Throws `unsupportedPlatform` |
| Linux | Not implemented for this API | Throws `unsupportedPlatform` |

## Diagnostic Support

The repository includes a Windows diagnostic utility target called `audio_monitor_property_dump`.

Use it when you need to inspect endpoint property values before and after changing `Listen to this device` manually in Windows.

Read the dedicated guide here:

- [Diagnostic tool](diagnostics.md)

## Next Steps

- Read the [installation guide](installation.md)
- See the [API guide](api.md)
- Review the [architecture notes](architecture.md)
