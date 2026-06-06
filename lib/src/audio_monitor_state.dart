class AudioMonitorState {
  const AudioMonitorState({
    required this.isMonitoring,
    required this.isMuted,
    required this.volume,
    this.inputDeviceId,
    this.outputDeviceId,
  });

  factory AudioMonitorState.fromMap(Map<Object?, Object?> map) {
    final isMonitoring = map['isMonitoring'];
    final isMuted = map['isMuted'];
    final volume = map['volume'];
    final inputDeviceId = map['inputDeviceId'];
    final outputDeviceId = map['outputDeviceId'];

    if (isMonitoring is! bool || isMuted is! bool || volume is! num) {
      throw const FormatException('Invalid audio monitor state payload.');
    }

    if (inputDeviceId != null && inputDeviceId is! String) {
      throw const FormatException('Invalid inputDeviceId value.');
    }

    if (outputDeviceId != null && outputDeviceId is! String) {
      throw const FormatException('Invalid outputDeviceId value.');
    }

    return AudioMonitorState(
      isMonitoring: isMonitoring,
      isMuted: isMuted,
      volume: volume.toDouble().clamp(0.0, 1.0),
      inputDeviceId: inputDeviceId as String?,
      outputDeviceId: outputDeviceId as String?,
    );
  }

  const AudioMonitorState.idle()
    : isMonitoring = false,
      isMuted = false,
      volume = 1.0,
      inputDeviceId = null,
      outputDeviceId = null;

  final bool isMonitoring;
  final bool isMuted;
  final double volume;
  final String? inputDeviceId;
  final String? outputDeviceId;

  @override
  bool operator ==(Object other) {
    return other is AudioMonitorState &&
        other.isMonitoring == isMonitoring &&
        other.isMuted == isMuted &&
        other.volume == volume &&
        other.inputDeviceId == inputDeviceId &&
        other.outputDeviceId == outputDeviceId;
  }

  @override
  int get hashCode =>
      Object.hash(isMonitoring, isMuted, volume, inputDeviceId, outputDeviceId);

  @override
  String toString() {
    return 'AudioMonitorState('
        'isMonitoring: $isMonitoring, '
        'isMuted: $isMuted, '
        'volume: $volume, '
        'inputDeviceId: $inputDeviceId, '
        'outputDeviceId: $outputDeviceId'
        ')';
  }
}
