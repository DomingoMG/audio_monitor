import 'audio_monitor_platform_interface.dart';
import 'src/audio_input_device.dart';
import 'src/audio_output_device.dart';
import 'src/native_listen_configuration.dart';

export 'src/audio_device_state.dart';
export 'src/audio_input_device.dart';
export 'src/audio_monitor_exception.dart';
export 'src/audio_output_device.dart';
export 'src/native_listen_configuration.dart';

class AudioMonitor {
  AudioMonitor._();

  static const String defaultOutputDeviceId = 'default';

  static Future<List<AudioInputDevice>> getInputDevices() {
    return AudioMonitorPlatform.instance.getInputDevices();
  }

  static Future<List<AudioOutputDevice>> getOutputDevices() {
    return AudioMonitorPlatform.instance.getOutputDevices();
  }

  static Future<NativeListenConfiguration> getNativeListenConfiguration({
    required String inputDeviceId,
  }) {
    return AudioMonitorPlatform.instance.getNativeListenConfiguration(
      inputDeviceId: inputDeviceId,
    );
  }

  static Future<void> enableNativeListen({
    required String inputDeviceId,
    required String outputDeviceId,
  }) {
    return AudioMonitorPlatform.instance.enableNativeListen(
      inputDeviceId: inputDeviceId,
      outputDeviceId: outputDeviceId,
    );
  }

  static Future<void> disableNativeListen({
    required String inputDeviceId,
  }) {
    return AudioMonitorPlatform.instance.disableNativeListen(
      inputDeviceId: inputDeviceId,
    );
  }

  static Future<void> setNativeListenOutputDevice({
    required String inputDeviceId,
    required String outputDeviceId,
  }) {
    return AudioMonitorPlatform.instance.setNativeListenOutputDevice(
      inputDeviceId: inputDeviceId,
      outputDeviceId: outputDeviceId,
    );
  }
}
