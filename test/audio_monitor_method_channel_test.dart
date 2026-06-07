import 'package:audio_monitor/audio_monitor.dart';
import 'package:audio_monitor/audio_monitor_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelAudioMonitor();
  const channel = MethodChannel('audio_monitor');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getInputDevices parses native payloads', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      if (methodCall.method == 'getInputDevices') {
        return [
          {
            'id': 'input-1',
            'name': 'Built-in Microphone',
            'isDefault': true,
            'state': 'active',
          },
        ];
      }
      return null;
    });

    final devices = await platform.getInputDevices();

    expect(devices.single.name, 'Built-in Microphone');
    expect(devices.single.state, AudioDeviceState.active);
  });

  test('getNativeListenConfiguration parses native payloads', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      if (methodCall.method == 'getNativeListenConfiguration') {
        return {
          'enabled': true,
          'outputDeviceId': 'output-1',
          'outputDeviceName': 'Speakers',
          'usesDefaultOutputDevice': false,
        };
      }
      return null;
    });

    final configuration = await platform.getNativeListenConfiguration(
      inputDeviceId: 'input-1',
    );

    expect(configuration.enabled, isTrue);
    expect(configuration.outputDeviceId, 'output-1');
    expect(configuration.outputDeviceName, 'Speakers');
  });

  test('platform errors are mapped to AudioMonitorException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      throw PlatformException(
        code: 'unsupportedPlatform',
        message: 'Native Windows listen control is only available on Windows.',
      );
    });

    expect(
      platform.getOutputDevices,
      throwsA(
        isA<AudioMonitorException>()
            .having(
              (error) => error.code,
              'code',
              AudioMonitorErrorCode.unsupportedPlatform,
            )
            .having(
              (error) => error.message,
              'message',
              'Native Windows listen control is only available on Windows.',
            ),
      ),
    );
  });

  test('enableNativeListen passes arguments over the method channel', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      capturedCall = methodCall;
      return null;
    });

    await platform.enableNativeListen(
      inputDeviceId: 'input-1',
      outputDeviceId: 'output-1',
    );

    expect(capturedCall?.method, 'enableNativeListen');
    expect(capturedCall?.arguments, <String, Object?>{
      'inputDeviceId': 'input-1',
      'outputDeviceId': 'output-1',
    });
  });

  test(
    'setNativeListenOutputDevice passes arguments over the method channel',
    () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        capturedCall = methodCall;
        return null;
      });

      await platform.setNativeListenOutputDevice(
        inputDeviceId: 'input-1',
        outputDeviceId: AudioMonitor.defaultOutputDeviceId,
      );

      expect(capturedCall?.method, 'setNativeListenOutputDevice');
      expect(capturedCall?.arguments, <String, Object?>{
        'inputDeviceId': 'input-1',
        'outputDeviceId': AudioMonitor.defaultOutputDeviceId,
      });
    },
  );
}
