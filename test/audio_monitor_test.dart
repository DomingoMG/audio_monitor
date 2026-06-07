import 'package:audio_monitor/audio_monitor.dart';
import 'package:audio_monitor/audio_monitor_method_channel.dart';
import 'package:audio_monitor/audio_monitor_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioMonitorPlatform
    with MockPlatformInterfaceMixin
    implements AudioMonitorPlatform {
  @override
  Future<List<AudioInputDevice>> getInputDevices() async {
    return const [
      AudioInputDevice(
        id: 'input-1',
        name: 'Mic 1',
        isDefault: true,
        state: AudioDeviceState.active,
      ),
    ];
  }

  @override
  Future<List<AudioOutputDevice>> getOutputDevices() async {
    return const [
      AudioOutputDevice(
        id: 'output-1',
        name: 'Speakers 1',
        isDefault: true,
        state: AudioDeviceState.active,
      ),
    ];
  }

  @override
  Future<NativeListenConfiguration> getNativeListenConfiguration({
    required String inputDeviceId,
  }) async {
    return const NativeListenConfiguration(
      enabled: true,
      outputDeviceId: 'output-1',
      outputDeviceName: 'Speakers 1',
      usesDefaultOutputDevice: false,
    );
  }

  @override
  Future<void> enableNativeListen({
    required String inputDeviceId,
    required String outputDeviceId,
  }) async {}

  @override
  Future<void> disableNativeListen({
    required String inputDeviceId,
  }) async {}

  @override
  Future<void> setNativeListenOutputDevice({
    required String inputDeviceId,
    required String outputDeviceId,
  }) async {}
}

void main() {
  final initialPlatform = AudioMonitorPlatform.instance;

  test('MethodChannelAudioMonitor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAudioMonitor>());
  });

  test('AudioMonitor forwards typed platform calls', () async {
    final mockPlatform = MockAudioMonitorPlatform();
    AudioMonitorPlatform.instance = mockPlatform;

    final inputs = await AudioMonitor.getInputDevices();
    final outputs = await AudioMonitor.getOutputDevices();
    final configuration = await AudioMonitor.getNativeListenConfiguration(
      inputDeviceId: 'input-1',
    );

    expect(inputs.single.state, AudioDeviceState.active);
    expect(outputs.single.state, AudioDeviceState.active);
    expect(configuration.enabled, isTrue);
    expect(configuration.outputDeviceId, 'output-1');
  });

  test('AudioInputDevice parses map payloads', () {
    final device = AudioInputDevice.fromMap(const {
      'id': 'input-1',
      'name': 'Mic 1',
      'isDefault': true,
      'state': 'active',
    });

    expect(device.name, 'Mic 1');
    expect(device.state, AudioDeviceState.active);
  });

  test('AudioOutputDevice parses map payloads', () {
    final device = AudioOutputDevice.fromMap(const {
      'id': 'output-1',
      'name': 'Speakers 1',
      'isDefault': false,
      'state': 'disabled',
    });

    expect(device.name, 'Speakers 1');
    expect(device.state, AudioDeviceState.disabled);
  });

  test('NativeListenConfiguration parses map payloads', () {
    final configuration = NativeListenConfiguration.fromMap(const {
      'enabled': true,
      'outputDeviceId': 'output-1',
      'outputDeviceName': 'Speakers 1',
      'usesDefaultOutputDevice': false,
    });

    expect(configuration.enabled, isTrue);
    expect(configuration.outputDeviceName, 'Speakers 1');
    expect(configuration.usesDefaultOutputDevice, isFalse);
  });

  test('AudioMonitorErrorCode falls back to nativeWindowsApiFailed', () {
    expect(
      AudioMonitorErrorCode.fromValue('unknownErrorCode'),
      AudioMonitorErrorCode.nativeWindowsApiFailed,
    );
  });
}
