import 'audio_monitor_platform_interface.dart';
import 'src/audio_monitor_device.dart';
import 'src/audio_monitor_state.dart';

export 'src/audio_monitor_device.dart';
export 'src/audio_monitor_exception.dart';
export 'src/audio_monitor_state.dart';

class AudioMonitor {
  const AudioMonitor();

  Future<List<AudioMonitorDevice>> getInputDevices() {
    return AudioMonitorPlatform.instance.getInputDevices();
  }

  Future<List<AudioMonitorDevice>> getOutputDevices() {
    return AudioMonitorPlatform.instance.getOutputDevices();
  }

  Future<void> start({
    required String inputDeviceId,
    required String outputDeviceId,
  }) {
    return AudioMonitorPlatform.instance.start(
      inputDeviceId: inputDeviceId,
      outputDeviceId: outputDeviceId,
    );
  }

  Future<void> stop() {
    return AudioMonitorPlatform.instance.stop();
  }

  Future<void> mute() {
    return AudioMonitorPlatform.instance.mute();
  }

  Future<void> unmute() {
    return AudioMonitorPlatform.instance.unmute();
  }

  Future<bool> isMuted() {
    return AudioMonitorPlatform.instance.isMuted();
  }

  Future<void> setVolume(double volume) {
    return AudioMonitorPlatform.instance.setVolume(volume);
  }

  Future<double> getVolume() {
    return AudioMonitorPlatform.instance.getVolume();
  }

  Future<bool> isMonitoring() {
    return AudioMonitorPlatform.instance.isMonitoring();
  }

  Future<AudioMonitorState> getState() {
    return AudioMonitorPlatform.instance.getState();
  }
}
