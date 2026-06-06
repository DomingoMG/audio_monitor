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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
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
  final AudioMonitor _monitor = const AudioMonitor();

  List<AudioMonitorDevice> _inputDevices = const [];
  List<AudioMonitorDevice> _outputDevices = const [];
  AudioMonitorDevice? _selectedInput;
  AudioMonitorDevice? _selectedOutput;
  AudioMonitorState _state = const AudioMonitorState.idle();
  String? _errorMessage;
  bool _isLoading = true;
  bool _isBusy = false;
  double _volumeDraft = 1.0;

  @override
  void initState() {
    super.initState();
    _loadDevicesAndState();
  }

  Future<void> _loadDevicesAndState() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final inputs = await _monitor.getInputDevices();
      final outputs = await _monitor.getOutputDevices();
      final state = await _monitor.getState();

      if (!mounted) {
        return;
      }

      setState(() {
        _inputDevices = inputs;
        _outputDevices = outputs;
        _state = state;
        _selectedInput = _resolveSelectedDevice(
          devices: inputs,
          selectedId: state.inputDeviceId,
        );
        _selectedOutput = _resolveSelectedDevice(
          devices: outputs,
          selectedId: state.outputDeviceId,
        );
        _volumeDraft = state.volume;
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

  AudioMonitorDevice? _resolveSelectedDevice({
    required List<AudioMonitorDevice> devices,
    required String? selectedId,
  }) {
    if (devices.isEmpty) {
      return null;
    }

    if (selectedId != null) {
      for (final device in devices) {
        if (device.id == selectedId) {
          return device;
        }
      }
    }

    for (final device in devices) {
      if (device.isDefault) {
        return device;
      }
    }

    return devices.first;
  }

  Future<void> _startMonitoring() async {
    final input = _selectedInput;
    final output = _selectedOutput;
    if (input == null || output == null) {
      setState(() {
        _errorMessage = 'Select both an input and an output device.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _monitor.start(inputDeviceId: input.id, outputDeviceId: output.id);
      final state = await _monitor.getState();
      if (!mounted) {
        return;
      }

      setState(() {
        _state = state;
        _volumeDraft = state.volume;
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

  Future<void> _stopMonitoring() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _monitor.stop();
      final state = await _monitor.getState();
      if (!mounted) {
        return;
      }

      setState(() {
        _state = state;
        _volumeDraft = state.volume;
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

  Future<void> _muteMonitoring() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _monitor.mute();
      final state = await _monitor.getState();
      if (!mounted) {
        return;
      }

      setState(() {
        _state = state;
        _volumeDraft = state.volume;
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

  Future<void> _unmuteMonitoring() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _monitor.unmute();
      final state = await _monitor.getState();
      if (!mounted) {
        return;
      }

      setState(() {
        _state = state;
        _volumeDraft = state.volume;
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

  Future<void> _setMonitorVolume(double volume) async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _monitor.setVolume(volume);
      final state = await _monitor.getState();
      if (!mounted) {
        return;
      }

      setState(() {
        _state = state;
        _volumeDraft = state.volume;
      });
    } on AudioMonitorException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '${error.code.name}: ${error.message}';
        _volumeDraft = _state.volume;
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
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading
                ? const CircularProgressIndicator()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live input monitoring',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Route a selected input device to an output device for real-time monitoring.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        _DeviceDropdown(
                          label: 'Input device',
                          devices: _inputDevices,
                          selectedDevice: _selectedInput,
                          onChanged: _state.isMonitoring
                              ? null
                              : (device) {
                                  setState(() {
                                    _selectedInput = device;
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
                        _DeviceDropdown(
                          label: 'Output device',
                          devices: _outputDevices,
                          selectedDevice: _selectedOutput,
                          onChanged: _state.isMonitoring
                              ? null
                              : (device) {
                                  setState(() {
                                    _selectedOutput = device;
                                  });
                                },
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton(
                              onPressed: _isBusy || _state.isMonitoring
                                  ? null
                                  : _startMonitoring,
                              child: const Text('Start monitoring'),
                            ),
                            OutlinedButton(
                              onPressed: _isBusy || !_state.isMonitoring
                                  ? null
                                  : _stopMonitoring,
                              child: const Text('Stop monitoring'),
                            ),
                            OutlinedButton(
                              onPressed:
                                  _isBusy ||
                                      !_state.isMonitoring ||
                                      _state.isMuted
                                  ? null
                                  : _muteMonitoring,
                              child: const Text('Mute monitor'),
                            ),
                            OutlinedButton(
                              onPressed:
                                  _isBusy ||
                                      !_state.isMonitoring ||
                                      !_state.isMuted
                                  ? null
                                  : _unmuteMonitoring,
                              child: const Text('Unmute monitor'),
                            ),
                            TextButton(
                              onPressed: _isBusy ? null : _loadDevicesAndState,
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
                                  'Current state',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Monitoring: ${_state.isMonitoring ? "active" : "stopped"}',
                                ),
                                Text('Muted: ${_state.isMuted ? "yes" : "no"}'),
                                Text(
                                  'Input: ${_state.inputDeviceId ?? "none"}',
                                ),
                                Text(
                                  'Output: ${_state.outputDeviceId ?? "none"}',
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Monitor volume: ${(_state.volume * 100).round()}%',
                                ),
                                Slider(
                                  value: _volumeDraft.clamp(0.0, 1.0),
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 20,
                                  label: '${(_volumeDraft * 100).round()}%',
                                  onChanged: _isBusy
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _volumeDraft = value;
                                          });
                                        },
                                  onChangeEnd: _isBusy
                                      ? null
                                      : _setMonitorVolume,
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
                          'macOS note: this version monitors to the current system default output. Set your MacBook speakers as default output first.',
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

class _DeviceDropdown extends StatelessWidget {
  const _DeviceDropdown({
    required this.label,
    required this.devices,
    required this.selectedDevice,
    required this.onChanged,
  });

  final String label;
  final List<AudioMonitorDevice> devices;
  final AudioMonitorDevice? selectedDevice;
  final ValueChanged<AudioMonitorDevice?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AudioMonitorDevice>(
          isExpanded: true,
          value: selectedDevice,
          items: devices
              .map(
                (device) => DropdownMenuItem<AudioMonitorDevice>(
                  value: device,
                  child: Text(
                    device.isDefault ? '${device.name} (default)' : device.name,
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
