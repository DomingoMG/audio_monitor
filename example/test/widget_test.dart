import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audio_monitor_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('audio_monitor');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          switch (methodCall.method) {
            case 'getInputDevices':
              return [
                {
                  'id': 'input-1',
                  'name': 'Built-in Microphone',
                  'isDefault': true,
                  'state': 'active',
                },
              ];
            case 'getOutputDevices':
              return [
                {
                  'id': 'output-1',
                  'name': 'Built-in Output',
                  'isDefault': true,
                  'state': 'active',
                },
              ];
            case 'getNativeListenConfiguration':
              return {
                'enabled': false,
                'outputDeviceId': null,
                'outputDeviceName': 'Built-in Output',
                'usesDefaultOutputDevice': true,
              };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('renders native listen controls', (tester) async {
    await tester.pumpWidget(const AudioMonitorExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Native Windows "Listen to this device"'), findsOneWidget);
    expect(find.text('Enable native listen'), findsOneWidget);
    expect(find.text('Disable native listen'), findsOneWidget);
  });
}
