import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_monitor_platform_interface.dart';
import 'src/audio_input_device.dart';
import 'src/audio_monitor_exception.dart';
import 'src/audio_output_device.dart';
import 'src/native_listen_configuration.dart';

class MethodChannelAudioMonitor extends AudioMonitorPlatform {
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('audio_monitor');

  @override
  Future<List<AudioInputDevice>> getInputDevices() async {
    final devices = await _invokeListMethod('getInputDevices');
    return devices
        .map(
          (device) =>
              AudioInputDevice.fromMap(Map<Object?, Object?>.from(device)),
        )
        .toList(growable: false);
  }

  @override
  Future<List<AudioOutputDevice>> getOutputDevices() async {
    final devices = await _invokeListMethod('getOutputDevices');
    return devices
        .map(
          (device) =>
              AudioOutputDevice.fromMap(Map<Object?, Object?>.from(device)),
        )
        .toList(growable: false);
  }

  @override
  Future<NativeListenConfiguration> getNativeListenConfiguration({
    required String inputDeviceId,
  }) async {
    try {
      final configuration =
          await methodChannel.invokeMapMethod<Object?, Object?>(
        'getNativeListenConfiguration',
        <String, Object?>{'inputDeviceId': inputDeviceId},
      );
      if (configuration == null) {
        return const NativeListenConfiguration.disabled();
      }

      return NativeListenConfiguration.fromMap(configuration);
    } on PlatformException catch (exception) {
      throw _mapPlatformException(exception);
    } on MissingPluginException {
      throw _unsupportedPlatform();
    }
  }

  @override
  Future<void> enableNativeListen({
    required String inputDeviceId,
    required String outputDeviceId,
  }) async {
    await _invokeVoidMethod('enableNativeListen', <String, Object?>{
      'inputDeviceId': inputDeviceId,
      'outputDeviceId': outputDeviceId,
    });
  }

  @override
  Future<void> disableNativeListen({
    required String inputDeviceId,
  }) async {
    await _invokeVoidMethod('disableNativeListen', <String, Object?>{
      'inputDeviceId': inputDeviceId,
    });
  }

  @override
  Future<void> setNativeListenOutputDevice({
    required String inputDeviceId,
    required String outputDeviceId,
  }) async {
    await _invokeVoidMethod('setNativeListenOutputDevice', <String, Object?>{
      'inputDeviceId': inputDeviceId,
      'outputDeviceId': outputDeviceId,
    });
  }

  Future<List<Map<dynamic, dynamic>>> _invokeListMethod(String method) async {
    try {
      final devices = await methodChannel.invokeListMethod<dynamic>(method);
      if (devices == null) {
        return const <Map<dynamic, dynamic>>[];
      }

      return devices.map((device) {
        if (device is! Map) {
          throw const FormatException('Invalid list payload received.');
        }
        return device;
      }).toList(growable: false);
    } on PlatformException catch (exception) {
      throw _mapPlatformException(exception);
    } on MissingPluginException {
      throw _unsupportedPlatform();
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
    } on MissingPluginException {
      throw _unsupportedPlatform();
    }
  }

  AudioMonitorException _mapPlatformException(PlatformException exception) {
    return AudioMonitorException(
      code: AudioMonitorErrorCode.fromValue(
        exception.code.isEmpty ? 'nativeWindowsApiFailed' : exception.code,
      ),
      message: exception.message ?? 'Native Windows audio monitoring error.',
      details: exception.details,
    );
  }

  AudioMonitorException _unsupportedPlatform() {
    return const AudioMonitorException(
      code: AudioMonitorErrorCode.unsupportedPlatform,
      message: 'Native Windows listen control is only available on Windows.',
    );
  }
}
