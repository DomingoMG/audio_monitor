#ifndef FLUTTER_PLUGIN_AUDIO_MONITOR_PLUGIN_H_
#define FLUTTER_PLUGIN_AUDIO_MONITOR_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace audio_monitor {

class AudioMonitorPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  AudioMonitorPlugin();

  virtual ~AudioMonitorPlugin();

  AudioMonitorPlugin(const AudioMonitorPlugin&) = delete;
  AudioMonitorPlugin& operator=(const AudioMonitorPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  struct AudioDeviceDescriptor {
    std::string id;
    std::string name;
    bool is_default;
    std::string state;
  };

  struct ListenConfiguration {
    bool enabled = false;
    std::optional<std::string> output_device_id;
    std::optional<std::string> output_device_name;
    bool uses_default_output_device = true;
  };

 private:
  std::vector<AudioDeviceDescriptor> GetInputDevices(
      std::string* error_code, std::string* error_message) const;
  std::vector<AudioDeviceDescriptor> GetOutputDevices(
      std::string* error_code, std::string* error_message) const;
  bool TryGetRequiredInputDeviceId(
      const flutter::EncodableValue* arguments, std::string* input_device_id) const;
  bool TryGetInputAndOutputDeviceIds(
      const flutter::EncodableValue* arguments, std::string* input_device_id,
      std::string* output_device_id) const;
  flutter::EncodableValue SerializeInputDevices(
      const std::vector<AudioDeviceDescriptor>& devices) const;
  flutter::EncodableValue SerializeOutputDevices(
      const std::vector<AudioDeviceDescriptor>& devices) const;
  flutter::EncodableValue SerializeListenConfiguration(
      const ListenConfiguration& configuration) const;
};

}  // namespace audio_monitor

#endif  // FLUTTER_PLUGIN_AUDIO_MONITOR_PLUGIN_H_
