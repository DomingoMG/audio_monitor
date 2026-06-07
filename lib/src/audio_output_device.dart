import 'audio_device_state.dart';

class AudioOutputDevice {
  const AudioOutputDevice({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.state,
  });

  factory AudioOutputDevice.fromMap(Map<Object?, Object?> map) {
    final id = map['id'];
    final name = map['name'];
    final isDefault = map['isDefault'];
    final state = map['state'];

    if (id is! String ||
        name is! String ||
        isDefault is! bool ||
        state is! String) {
      throw const FormatException('Invalid audio output device payload.');
    }

    return AudioOutputDevice(
      id: id,
      name: name,
      isDefault: isDefault,
      state: AudioDeviceState.fromValue(state),
    );
  }

  final String id;
  final String name;
  final bool isDefault;
  final AudioDeviceState state;

  @override
  bool operator ==(Object other) {
    return other is AudioOutputDevice &&
        other.id == id &&
        other.name == name &&
        other.isDefault == isDefault &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(id, name, isDefault, state);
}
