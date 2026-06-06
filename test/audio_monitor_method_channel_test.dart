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
                'id': '1',
                'name': 'Built-in Microphone',
                'isDefault': true,
                'type': 'input',
              },
            ];
          }
          return null;
        });

    final devices = await platform.getInputDevices();

    expect(devices.single.name, 'Built-in Microphone');
    expect(devices.single.type, AudioMonitorDeviceType.input);
  });

  test('getState parses native payloads', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          if (methodCall.method == 'getState') {
            return {
              'isMonitoring': true,
              'isMuted': true,
              'volume': 0.6,
              'inputDeviceId': '1',
              'outputDeviceId': '2',
            };
          }
          return null;
        });

    final state = await platform.getState();

    expect(state.isMonitoring, isTrue);
    expect(state.isMuted, isTrue);
    expect(state.volume, 0.6);
    expect(state.inputDeviceId, '1');
    expect(state.outputDeviceId, '2');
  });

  test('platform errors are mapped to AudioMonitorException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          throw PlatformException(
            code: 'platformNotSupported',
            message: 'Windows support is not implemented yet.',
          );
        });

    expect(
      platform.getOutputDevices,
      throwsA(
        isA<AudioMonitorException>()
            .having(
              (error) => error.code,
              'code',
              AudioMonitorErrorCode.platformNotSupported,
            )
            .having(
              (error) => error.message,
              'message',
              'Windows support is not implemented yet.',
            ),
      ),
    );
  });

  test('start passes arguments over the method channel', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          capturedCall = methodCall;
          return null;
        });

    await platform.start(inputDeviceId: 'input-1', outputDeviceId: 'output-1');

    expect(capturedCall?.method, 'start');
    expect(capturedCall?.arguments, <String, Object?>{
      'inputDeviceId': 'input-1',
      'outputDeviceId': 'output-1',
    });
  });

  test('mute passes method over the channel', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          capturedCall = methodCall;
          return null;
        });

    await platform.mute();

    expect(capturedCall?.method, 'mute');
  });

  test('isMuted defaults to false when the platform returns null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async => null);

    expect(await platform.isMuted(), isFalse);
  });

  test('setVolume passes arguments over the method channel', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          capturedCall = methodCall;
          return null;
        });

    await platform.setVolume(0.35);

    expect(capturedCall?.method, 'setVolume');
    expect(capturedCall?.arguments, <String, Object?>{'volume': 0.35});
  });

  test('getVolume defaults to 1.0 when the platform returns null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async => null);

    expect(await platform.getVolume(), 1.0);
  });
}
