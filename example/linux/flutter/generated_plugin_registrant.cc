//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audio_monitor/audio_monitor_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) audio_monitor_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AudioMonitorPlugin");
  audio_monitor_plugin_register_with_registrar(audio_monitor_registrar);
}
