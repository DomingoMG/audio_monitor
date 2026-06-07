# Diagnostics

## `audio_monitor_property_dump`

The Windows project includes a diagnostic executable target named `audio_monitor_property_dump`.

This tool is not part of the public Flutter API. It exists to help inspect native endpoint properties while developing or debugging the Windows backend.

## What it does

It dumps property keys and values for:

- capture endpoints
- render endpoints

This is useful for comparing endpoint state:

1. before enabling `Listen to this device` manually in Windows
2. after enabling it and selecting a playback device

## When to use it

Use the dump tool when:

- a driver behaves differently on one machine
- the Sound Control Panel does not reflect the expected state
- you need to verify which endpoint properties changed
- you are debugging support for a new audio device

## Typical workflow

1. Run `audio_monitor_property_dump`
2. Save the output
3. Enable or change `Listen to this device` manually in Sound Control Panel
4. Run `audio_monitor_property_dump` again
5. Compare both outputs

## Important note

This tool is intended for diagnostics only. It should not be treated as a user-facing CLI or a stable contract for external automation.
