enum AudioMonitorDeviceType {
  input,
  output;

  static AudioMonitorDeviceType fromValue(String value) {
    switch (value) {
      case 'input':
        return AudioMonitorDeviceType.input;
      case 'output':
        return AudioMonitorDeviceType.output;
    }

    throw FormatException('Unknown audio monitor device type: $value');
  }
}

class AudioMonitorDevice {
  const AudioMonitorDevice({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.type,
  });

  factory AudioMonitorDevice.fromMap(Map<Object?, Object?> map) {
    final id = map['id'];
    final name = map['name'];
    final isDefault = map['isDefault'];
    final type = map['type'];

    if (id is! String ||
        name is! String ||
        isDefault is! bool ||
        type is! String) {
      throw const FormatException('Invalid audio monitor device payload.');
    }

    return AudioMonitorDevice(
      id: id,
      name: name,
      isDefault: isDefault,
      type: AudioMonitorDeviceType.fromValue(type),
    );
  }

  final String id;
  final String name;
  final bool isDefault;
  final AudioMonitorDeviceType type;

  @override
  bool operator ==(Object other) {
    return other is AudioMonitorDevice &&
        other.id == id &&
        other.name == name &&
        other.isDefault == isDefault &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, name, isDefault, type);

  @override
  String toString() {
    return 'AudioMonitorDevice('
        'id: $id, '
        'name: $name, '
        'isDefault: $isDefault, '
        'type: $type'
        ')';
  }
}
