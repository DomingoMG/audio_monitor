enum AudioMonitorErrorCode {
  inputDeviceNotFound,
  outputDeviceNotFound,
  deviceNotActive,
  listenConfigurationUnavailable,
  listenConfigurationUnsupported,
  permissionDenied,
  nativeWindowsApiFailed,
  unsupportedPlatform;

  static AudioMonitorErrorCode fromValue(String value) {
    switch (value) {
      case 'inputDeviceNotFound':
        return AudioMonitorErrorCode.inputDeviceNotFound;
      case 'outputDeviceNotFound':
        return AudioMonitorErrorCode.outputDeviceNotFound;
      case 'deviceNotActive':
        return AudioMonitorErrorCode.deviceNotActive;
      case 'listenConfigurationUnavailable':
        return AudioMonitorErrorCode.listenConfigurationUnavailable;
      case 'listenConfigurationUnsupported':
        return AudioMonitorErrorCode.listenConfigurationUnsupported;
      case 'permissionDenied':
        return AudioMonitorErrorCode.permissionDenied;
      case 'nativeWindowsApiFailed':
        return AudioMonitorErrorCode.nativeWindowsApiFailed;
      case 'unsupportedPlatform':
        return AudioMonitorErrorCode.unsupportedPlatform;
    }

    return AudioMonitorErrorCode.nativeWindowsApiFailed;
  }
}

class AudioMonitorException implements Exception {
  const AudioMonitorException({
    required this.code,
    required this.message,
    this.details,
  });

  final AudioMonitorErrorCode code;
  final String message;
  final Object? details;

  @override
  String toString() {
    return 'AudioMonitorException('
        'code: ${code.name}, '
        'message: $message, '
        'details: $details'
        ')';
  }
}
