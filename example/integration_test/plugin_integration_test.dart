import 'package:audio_monitor/audio_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('device listing and state calls return typed values', (_) async {
    const plugin = AudioMonitor();

    try {
      final inputs = await plugin.getInputDevices();
      final outputs = await plugin.getOutputDevices();
      final state = await plugin.getState();

      expect(inputs, isA<List<AudioMonitorDevice>>());
      expect(outputs, isA<List<AudioMonitorDevice>>());
      expect(state, isA<AudioMonitorState>());
    } on AudioMonitorException catch (error) {
      expect(
        error.code,
        anyOf(
          AudioMonitorErrorCode.platformNotSupported,
          AudioMonitorErrorCode.permissionDenied,
          AudioMonitorErrorCode.nativeAudioError,
        ),
      );
    }
  });
}
