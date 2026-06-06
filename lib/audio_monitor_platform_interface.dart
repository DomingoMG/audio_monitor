import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'audio_monitor_method_channel.dart';
import 'src/audio_monitor_device.dart';
import 'src/audio_monitor_state.dart';

abstract class AudioMonitorPlatform extends PlatformInterface {
  AudioMonitorPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioMonitorPlatform _instance = MethodChannelAudioMonitor();

  static AudioMonitorPlatform get instance => _instance;

  static set instance(AudioMonitorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<AudioMonitorDevice>> getInputDevices() {
    throw UnimplementedError('getInputDevices() has not been implemented.');
  }

  Future<List<AudioMonitorDevice>> getOutputDevices() {
    throw UnimplementedError('getOutputDevices() has not been implemented.');
  }

  Future<void> start({
    required String inputDeviceId,
    required String outputDeviceId,
  }) {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<void> mute() {
    throw UnimplementedError('mute() has not been implemented.');
  }

  Future<void> unmute() {
    throw UnimplementedError('unmute() has not been implemented.');
  }

  Future<bool> isMuted() {
    throw UnimplementedError('isMuted() has not been implemented.');
  }

  Future<void> setVolume(double volume) {
    throw UnimplementedError('setVolume() has not been implemented.');
  }

  Future<double> getVolume() {
    throw UnimplementedError('getVolume() has not been implemented.');
  }

  Future<bool> isMonitoring() {
    throw UnimplementedError('isMonitoring() has not been implemented.');
  }

  Future<AudioMonitorState> getState() {
    throw UnimplementedError('getState() has not been implemented.');
  }
}
