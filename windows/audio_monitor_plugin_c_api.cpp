#include "include/audio_monitor/audio_monitor_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "audio_monitor_plugin.h"

void AudioMonitorPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  audio_monitor::AudioMonitorPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
