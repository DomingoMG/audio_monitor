#ifndef FLUTTER_PLUGIN_AUDIO_MONITOR_PLUGIN_H_
#define FLUTTER_PLUGIN_AUDIO_MONITOR_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace audio_monitor {

class AudioMonitorPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AudioMonitorPlugin();

  virtual ~AudioMonitorPlugin();

  // Disallow copy and assign.
  AudioMonitorPlugin(const AudioMonitorPlugin&) = delete;
  AudioMonitorPlugin& operator=(const AudioMonitorPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace audio_monitor

#endif  // FLUTTER_PLUGIN_AUDIO_MONITOR_PLUGIN_H_
