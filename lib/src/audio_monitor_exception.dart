enum AudioMonitorErrorCode {
  deviceNotFound,
  permissionDenied,
  monitoringAlreadyActive,
  monitoringNotActive,
  platformNotSupported,
  nativeAudioError;

  static AudioMonitorErrorCode fromValue(String value) {
    switch (value) {
      case 'deviceNotFound':
        return AudioMonitorErrorCode.deviceNotFound;
      case 'permissionDenied':
        return AudioMonitorErrorCode.permissionDenied;
      case 'monitoringAlreadyActive':
        return AudioMonitorErrorCode.monitoringAlreadyActive;
      case 'monitoringNotActive':
        return AudioMonitorErrorCode.monitoringNotActive;
      case 'platformNotSupported':
        return AudioMonitorErrorCode.platformNotSupported;
      case 'nativeAudioError':
        return AudioMonitorErrorCode.nativeAudioError;
    }

    return AudioMonitorErrorCode.nativeAudioError;
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
