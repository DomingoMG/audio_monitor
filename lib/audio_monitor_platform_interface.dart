import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'audio_monitor_method_channel.dart';
import 'src/audio_input_device.dart';
import 'src/audio_output_device.dart';
import 'src/native_listen_configuration.dart';

abstract class AudioMonitorPlatform extends PlatformInterface {
  AudioMonitorPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioMonitorPlatform _instance = MethodChannelAudioMonitor();

  static AudioMonitorPlatform get instance => _instance;

  static set instance(AudioMonitorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<AudioInputDevice>> getInputDevices() {
    throw UnimplementedError('getInputDevices() has not been implemented.');
  }

  Future<List<AudioOutputDevice>> getOutputDevices() {
    throw UnimplementedError('getOutputDevices() has not been implemented.');
  }

  Future<NativeListenConfiguration> getNativeListenConfiguration({
    required String inputDeviceId,
  }) {
    throw UnimplementedError(
      'getNativeListenConfiguration() has not been implemented.',
    );
  }

  Future<void> enableNativeListen({
    required String inputDeviceId,
    required String outputDeviceId,
  }) {
    throw UnimplementedError('enableNativeListen() has not been implemented.');
  }

  Future<void> disableNativeListen({
    required String inputDeviceId,
  }) {
    throw UnimplementedError('disableNativeListen() has not been implemented.');
  }

  Future<void> setNativeListenOutputDevice({
    required String inputDeviceId,
    required String outputDeviceId,
  }) {
    throw UnimplementedError(
      'setNativeListenOutputDevice() has not been implemented.',
    );
  }
}
