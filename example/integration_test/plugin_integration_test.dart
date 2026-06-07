import 'package:audio_monitor/audio_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('device listing and native listen calls return typed values', (
    _,
  ) async {
    try {
      final inputs = await AudioMonitor.getInputDevices();
      final outputs = await AudioMonitor.getOutputDevices();

      expect(inputs, isA<List<AudioInputDevice>>());
      expect(outputs, isA<List<AudioOutputDevice>>());

      if (inputs.isNotEmpty) {
        final configuration = await AudioMonitor.getNativeListenConfiguration(
          inputDeviceId: inputs.first.id,
        );
        expect(configuration, isA<NativeListenConfiguration>());
      }
    } on AudioMonitorException catch (error) {
      expect(
        error.code,
        anyOf(
          AudioMonitorErrorCode.unsupportedPlatform,
          AudioMonitorErrorCode.permissionDenied,
          AudioMonitorErrorCode.listenConfigurationUnavailable,
          AudioMonitorErrorCode.listenConfigurationUnsupported,
          AudioMonitorErrorCode.nativeWindowsApiFailed,
        ),
      );
    }
  });
}
