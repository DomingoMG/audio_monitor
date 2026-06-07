import 'package:audio_monitor/audio_monitor.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AudioMonitorExampleApp());
}

class AudioMonitorExampleApp extends StatelessWidget {
  const AudioMonitorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Monitor Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const AudioMonitorExamplePage(),
    );
  }
}

class AudioMonitorExamplePage extends StatefulWidget {
  const AudioMonitorExamplePage({super.key});

  @override
  State<AudioMonitorExamplePage> createState() =>
      _AudioMonitorExamplePageState();
}

class _AudioMonitorExamplePageState extends State<AudioMonitorExamplePage> {
  List<AudioInputDevice> _inputDevices = const [];
  List<AudioOutputDevice> _outputDevices = const [];
  String? _selectedInputId;
  String _selectedOutputId = AudioMonitor.defaultOutputDeviceId;
  NativeListenConfiguration? _configuration;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final inputs = await AudioMonitor.getInputDevices();
      final outputs = await AudioMonitor.getOutputDevices();
      final selectedInputId = _resolveInputId(inputs, _selectedInputId);
      final configuration = selectedInputId == null
          ? null
          : await AudioMonitor.getNativeListenConfiguration(
              inputDeviceId: selectedInputId,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _inputDevices = inputs;
        _outputDevices = outputs;
        _selectedInputId = selectedInputId;
        _configuration = configuration;
        _selectedOutputId = _resolveOutputId(outputs, configuration);
      });
    } on AudioMonitorException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '${error.code.name}: ${error.message}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _resolveInputId(List<AudioInputDevice> inputs, String? preferredId) {
    if (inputs.isEmpty) {
      return null;
    }

    for (final device in inputs) {
      if (device.id == preferredId) {
        return device.id;
      }
    }

    for (final device in inputs) {
      if (device.isDefault) {
        return device.id;
      }
    }

    return inputs.first.id;
  }

  String _resolveOutputId(
    List<AudioOutputDevice> outputs,
    NativeListenConfiguration? configuration,
  ) {
    if (configuration == null || configuration.usesDefaultOutputDevice) {
      return AudioMonitor.defaultOutputDeviceId;
    }

    final outputDeviceId = configuration.outputDeviceId;
    if (outputDeviceId == null) {
      return AudioMonitor.defaultOutputDeviceId;
    }

    for (final device in outputs) {
      if (device.id == outputDeviceId) {
        return outputDeviceId;
      }
    }

    return AudioMonitor.defaultOutputDeviceId;
  }

  Future<void> _refreshConfiguration() async {
    final inputDeviceId = _selectedInputId;
    if (inputDeviceId == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final configuration = await AudioMonitor.getNativeListenConfiguration(
        inputDeviceId: inputDeviceId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _configuration = configuration;
        _selectedOutputId = _resolveOutputId(_outputDevices, configuration);
      });
    } on AudioMonitorException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '${error.code.name}: ${error.message}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _enableNativeListen() async {
    final inputDeviceId = _selectedInputId;
    if (inputDeviceId == null) {
      setState(() {
        _errorMessage = 'Select an input device first.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await AudioMonitor.enableNativeListen(
        inputDeviceId: inputDeviceId,
        outputDeviceId: _selectedOutputId,
      );
      await _refreshConfiguration();
    } on AudioMonitorException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '${error.code.name}: ${error.message}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _disableNativeListen() async {
    final inputDeviceId = _selectedInputId;
    if (inputDeviceId == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await AudioMonitor.disableNativeListen(inputDeviceId: inputDeviceId);
      await _refreshConfiguration();
    } on AudioMonitorException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '${error.code.name}: ${error.message}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _setOutputDevice() async {
    final inputDeviceId = _selectedInputId;
    if (inputDeviceId == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await AudioMonitor.setNativeListenOutputDevice(
        inputDeviceId: inputDeviceId,
        outputDeviceId: _selectedOutputId,
      );
      await _refreshConfiguration();
    } on AudioMonitorException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '${error.code.name}: ${error.message}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Monitor')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading
                ? const CircularProgressIndicator()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Native Windows "Listen to this device"',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This example configures the operating system built-in microphone monitoring feature instead of creating a custom audio pipeline.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        _InputDropdown(
                          devices: _inputDevices,
                          selectedDeviceId: _selectedInputId,
                          onChanged: _isBusy
                              ? null
                              : (value) async {
                                  setState(() {
                                    _selectedInputId = value;
                                  });
                                  await _refreshConfiguration();
                                },
                        ),
                        const SizedBox(height: 16),
                        _OutputDropdown(
                          devices: _outputDevices,
                          selectedDeviceId: _selectedOutputId,
                          onChanged: _isBusy
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedOutputId = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton(
                              onPressed: _isBusy ? null : _enableNativeListen,
                              child: const Text('Enable native listen'),
                            ),
                            OutlinedButton(
                              onPressed: _isBusy ? null : _disableNativeListen,
                              child: const Text('Disable native listen'),
                            ),
                            OutlinedButton(
                              onPressed: _isBusy ? null : _setOutputDevice,
                              child: const Text('Apply output device'),
                            ),
                            TextButton(
                              onPressed: _isBusy ? null : _refreshConfiguration,
                              child: const Text('Refresh configuration'),
                            ),
                            TextButton(
                              onPressed: _isBusy ? null : _refreshAll,
                              child: const Text('Refresh devices'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current native listen state',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Enabled: ${_configuration?.enabled == true ? "yes" : "no"}',
                                ),
                                Text(
                                  'Input device: ${_selectedInputId ?? "none"}',
                                ),
                                Text(
                                  'Uses default output: ${_configuration?.usesDefaultOutputDevice == true ? "yes" : "no"}',
                                ),
                                Text(
                                  'Output device id: ${_configuration?.outputDeviceId ?? "default playback device"}',
                                ),
                                Text(
                                  'Output device name: ${_configuration?.outputDeviceName ?? "default playback device"}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Material(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Manual check: after enabling native listen, open Sound Control Panel > Recording > your microphone > Properties > Listen and confirm that the checkbox and playback device match this app.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _InputDropdown extends StatelessWidget {
  const _InputDropdown({
    required this.devices,
    required this.selectedDeviceId,
    required this.onChanged,
  });

  final List<AudioInputDevice> devices;
  final String? selectedDeviceId;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Input device',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedDeviceId,
          items: devices
              .map(
                (device) => DropdownMenuItem<String>(
                  value: device.id,
                  child: Text(
                    _deviceLabel(device.name, device.isDefault, device.state),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _OutputDropdown extends StatelessWidget {
  const _OutputDropdown({
    required this.devices,
    required this.selectedDeviceId,
    required this.onChanged,
  });

  final List<AudioOutputDevice> devices;
  final String selectedDeviceId;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Playback through this device',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedDeviceId,
          items: [
            const DropdownMenuItem<String>(
              value: AudioMonitor.defaultOutputDeviceId,
              child: Text('Default playback device'),
            ),
            ...devices.map(
              (device) => DropdownMenuItem<String>(
                value: device.id,
                child: Text(
                  _deviceLabel(device.name, device.isDefault, device.state),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

String _deviceLabel(String name, bool isDefault, AudioDeviceState state) {
  final defaultSuffix = isDefault ? ' (default)' : '';
  return '$name$defaultSuffix [${state.name}]';
}
