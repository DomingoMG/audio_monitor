enum AudioDeviceState {
  active,
  disabled,
  unplugged,
  notPresent,
  unknown;

  static AudioDeviceState fromValue(String value) {
    switch (value) {
      case 'active':
        return AudioDeviceState.active;
      case 'disabled':
        return AudioDeviceState.disabled;
      case 'unplugged':
        return AudioDeviceState.unplugged;
      case 'notPresent':
        return AudioDeviceState.notPresent;
      case 'unknown':
        return AudioDeviceState.unknown;
    }

    throw FormatException('Unknown audio device state: $value');
  }
}
