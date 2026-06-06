#include "audio_monitor_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace audio_monitor {

// static
void AudioMonitorPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "audio_monitor",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AudioMonitorPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AudioMonitorPlugin::AudioMonitorPlugin() {}

AudioMonitorPlugin::~AudioMonitorPlugin() {}

void AudioMonitorPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string method_name = method_call.method_name();

  if (method_name == "getInputDevices" || method_name == "getOutputDevices" ||
      method_name == "start" || method_name == "stop" ||
      method_name == "mute" || method_name == "unmute" ||
      method_name == "isMuted" || method_name == "setVolume" ||
      method_name == "getVolume" || method_name == "isMonitoring" ||
      method_name == "getState") {
    result->Error(
        "platformNotSupported",
        "Windows support is not implemented yet. The planned Windows backend "
        "will target the native listen-to-device monitoring behavior.");
  } else {
    result->NotImplemented();
  }
}

}  // namespace audio_monitor
