import 'package:audio_monitor/audio_monitor.dart';
import 'package:audio_monitor/audio_monitor_method_channel.dart';
import 'package:audio_monitor/audio_monitor_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioMonitorPlatform
    with MockPlatformInterfaceMixin
    implements AudioMonitorPlatform {
  @override
  Future<List<AudioMonitorDevice>> getInputDevices() async {
    return const [
      AudioMonitorDevice(
        id: 'input-1',
        name: 'Built-in Microphone',
        isDefault: true,
        type: AudioMonitorDeviceType.input,
      ),
    ];
  }

  @override
  Future<List<AudioMonitorDevice>> getOutputDevices() async {
    return const [
      AudioMonitorDevice(
        id: 'output-1',
        name: 'Built-in Output',
        isDefault: true,
        type: AudioMonitorDeviceType.output,
      ),
    ];
  }

  @override
  Future<void> start({
    required String inputDeviceId,
    required String outputDeviceId,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> mute() async {}

  @override
  Future<void> unmute() async {}

  @override
  Future<bool> isMuted() async => true;

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<double> getVolume() async => 0.6;

  @override
  Future<bool> isMonitoring() async => true;

  @override
  Future<AudioMonitorState> getState() async {
    return const AudioMonitorState(
      isMonitoring: true,
      isMuted: true,
      volume: 0.6,
      inputDeviceId: 'input-1',
      outputDeviceId: 'output-1',
    );
  }
}

void main() {
  final AudioMonitorPlatform initialPlatform = AudioMonitorPlatform.instance;

  test('$MethodChannelAudioMonitor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAudioMonitor>());
  });

  test('AudioMonitor forwards typed platform calls', () async {
    const monitor = AudioMonitor();
    AudioMonitorPlatform.instance = MockAudioMonitorPlatform();

    final inputs = await monitor.getInputDevices();
    final outputs = await monitor.getOutputDevices();
    final state = await monitor.getState();

    expect(inputs.single.name, 'Built-in Microphone');
    expect(outputs.single.type, AudioMonitorDeviceType.output);
    expect(await monitor.isMonitoring(), isTrue);
    expect(await monitor.isMuted(), isTrue);
    expect(await monitor.getVolume(), 0.6);
    expect(state.outputDeviceId, 'output-1');
  });

  test('AudioMonitorDevice parses map payloads', () {
    final device = AudioMonitorDevice.fromMap(const {
      'id': 'device-123',
      'name': 'USB Interface',
      'isDefault': false,
      'type': 'input',
    });

    expect(device.id, 'device-123');
    expect(device.type, AudioMonitorDeviceType.input);
    expect(device.isDefault, isFalse);
  });

  test('AudioMonitorState parses map payloads', () {
    final state = AudioMonitorState.fromMap(const {
      'isMonitoring': true,
      'isMuted': true,
      'volume': 0.6,
      'inputDeviceId': 'input-1',
      'outputDeviceId': 'output-1',
    });

    expect(state.isMonitoring, isTrue);
    expect(state.isMuted, isTrue);
    expect(state.volume, 0.6);
    expect(state.inputDeviceId, 'input-1');
    expect(state.outputDeviceId, 'output-1');
  });

  test('AudioMonitorErrorCode falls back to nativeAudioError', () {
    expect(
      AudioMonitorErrorCode.fromValue('unexpected-code'),
      AudioMonitorErrorCode.nativeAudioError,
    );
  });
}
