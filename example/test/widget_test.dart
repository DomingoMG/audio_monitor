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
                  'type': 'input',
                },
              ];
            case 'getOutputDevices':
              return [
                {
                  'id': 'output-1',
                  'name': 'Built-in Output',
                  'isDefault': true,
                  'type': 'output',
                },
              ];
            case 'getState':
              return {
                'isMonitoring': false,
                'isMuted': false,
                'volume': 1.0,
                'inputDeviceId': null,
                'outputDeviceId': null,
              };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('renders audio monitor controls', (tester) async {
    await tester.pumpWidget(const AudioMonitorExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Live input monitoring'), findsOneWidget);
    expect(find.text('Start monitoring'), findsOneWidget);
    expect(find.text('Stop monitoring'), findsOneWidget);
  });
}
