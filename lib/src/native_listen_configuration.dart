class NativeListenConfiguration {
  const NativeListenConfiguration({
    required this.enabled,
    required this.outputDeviceId,
    required this.outputDeviceName,
    required this.usesDefaultOutputDevice,
  });

  const NativeListenConfiguration.disabled()
      : enabled = false,
        outputDeviceId = null,
        outputDeviceName = null,
        usesDefaultOutputDevice = true;

  factory NativeListenConfiguration.fromMap(Map<Object?, Object?> map) {
    final enabled = map['enabled'];
    final outputDeviceId = map['outputDeviceId'];
    final outputDeviceName = map['outputDeviceName'];
    final usesDefaultOutputDevice = map['usesDefaultOutputDevice'];

    if (enabled is! bool || usesDefaultOutputDevice is! bool) {
      throw const FormatException(
        'Invalid native listen configuration payload.',
      );
    }

    if (outputDeviceId != null && outputDeviceId is! String) {
      throw const FormatException('Invalid outputDeviceId value.');
    }

    if (outputDeviceName != null && outputDeviceName is! String) {
      throw const FormatException('Invalid outputDeviceName value.');
    }

    return NativeListenConfiguration(
      enabled: enabled,
      outputDeviceId: outputDeviceId as String?,
      outputDeviceName: outputDeviceName as String?,
      usesDefaultOutputDevice: usesDefaultOutputDevice,
    );
  }

  final bool enabled;
  final String? outputDeviceId;
  final String? outputDeviceName;
  final bool usesDefaultOutputDevice;

  @override
  bool operator ==(Object other) {
    return other is NativeListenConfiguration &&
        other.enabled == enabled &&
        other.outputDeviceId == outputDeviceId &&
        other.outputDeviceName == outputDeviceName &&
        other.usesDefaultOutputDevice == usesDefaultOutputDevice;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        outputDeviceId,
        outputDeviceName,
        usesDefaultOutputDevice,
      );
}
