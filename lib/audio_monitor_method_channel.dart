import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_monitor_platform_interface.dart';
import 'src/audio_monitor_device.dart';
import 'src/audio_monitor_exception.dart';
import 'src/audio_monitor_state.dart';

class MethodChannelAudioMonitor extends AudioMonitorPlatform {
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('audio_monitor');

  @override
  Future<List<AudioMonitorDevice>> getInputDevices() async {
    final devices = await _invokeListMethod('getInputDevices');
    return devices
        .map(
          (device) =>
              AudioMonitorDevice.fromMap(Map<Object?, Object?>.from(device)),
        )
        .toList(growable: false);
  }

  @override
  Future<List<AudioMonitorDevice>> getOutputDevices() async {
    final devices = await _invokeListMethod('getOutputDevices');
    return devices
        .map(
          (device) =>
              AudioMonitorDevice.fromMap(Map<Object?, Object?>.from(device)),
        )
        .toList(growable: false);
  }

  @override
  Future<void> start({
    required String inputDeviceId,
    required String outputDeviceId,
  }) async {
    await _invokeVoidMethod('start', <String, Object?>{
      'inputDeviceId': inputDeviceId,
      'outputDeviceId': outputDeviceId,
    });
  }

  @override
  Future<void> stop() async {
    await _invokeVoidMethod('stop');
  }

  @override
  Future<void> mute() async {
    await _invokeVoidMethod('mute');
  }

  @override
  Future<void> unmute() async {
    await _invokeVoidMethod('unmute');
  }

  @override
  Future<bool> isMuted() async {
    try {
      final isMuted = await methodChannel.invokeMethod<bool>('isMuted');
      return isMuted ?? false;
    } on PlatformException catch (exception) {
      throw _mapPlatformException(exception);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    await _invokeVoidMethod('setVolume', <String, Object?>{'volume': volume});
  }

  @override
  Future<double> getVolume() async {
    try {
      final volume = await methodChannel.invokeMethod<double>('getVolume');
      return (volume ?? 1.0).clamp(0.0, 1.0);
    } on PlatformException catch (exception) {
      throw _mapPlatformException(exception);
    }
  }

  @override
  Future<bool> isMonitoring() async {
    try {
      final isMonitoring = await methodChannel.invokeMethod<bool>(
        'isMonitoring',
      );
      return isMonitoring ?? false;
    } on PlatformException catch (exception) {
      throw _mapPlatformException(exception);
    }
  }

  @override
  Future<AudioMonitorState> getState() async {
    try {
      final state = await methodChannel.invokeMapMethod<Object?, Object?>(
        'getState',
      );
      if (state == null) {
        return const AudioMonitorState.idle();
      }

      return AudioMonitorState.fromMap(state);
    } on PlatformException catch (exception) {
      throw _mapPlatformException(exception);
    }
  }

  Future<List<Map<dynamic, dynamic>>> _invokeListMethod(String method) async {
    try {
      final devices = await methodChannel.invokeListMethod<dynamic>(method);
      if (devices == null) {
        return const <Map<dynamic, dynamic>>[];
      }

      return devices
          .map((device) {
            if (device is! Map) {
              throw const FormatException('Invalid list payload received.');
            }
            return device;
          })
          .toList(growable: false);
    } on PlatformException catch (exception) {
      throw _mapPlatformException(exception);
    }
  }

  Future<void> _invokeVoidMethod(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      await methodChannel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (exception) {
      throw _mapPlatformException(exception);
    }
  }

  AudioMonitorException _mapPlatformException(PlatformException exception) {
    return AudioMonitorException(
      code: AudioMonitorErrorCode.fromValue(
        exception.code.isEmpty ? 'nativeAudioError' : exception.code,
      ),
      message: exception.message ?? 'Native audio monitoring error.',
      details: exception.details,
    );
  }
}
