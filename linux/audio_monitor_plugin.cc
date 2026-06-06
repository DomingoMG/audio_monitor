#include "include/audio_monitor/audio_monitor_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <cstring>

#include "audio_monitor_plugin_private.h"

#define AUDIO_MONITOR_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), audio_monitor_plugin_get_type(), \
                              AudioMonitorPlugin))

struct _AudioMonitorPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AudioMonitorPlugin, audio_monitor_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void audio_monitor_plugin_handle_method_call(
    AudioMonitorPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getInputDevices") == 0 ||
      strcmp(method, "getOutputDevices") == 0 ||
      strcmp(method, "start") == 0 ||
      strcmp(method, "stop") == 0 ||
      strcmp(method, "mute") == 0 ||
      strcmp(method, "unmute") == 0 ||
      strcmp(method, "isMuted") == 0 ||
      strcmp(method, "setVolume") == 0 ||
      strcmp(method, "getVolume") == 0 ||
      strcmp(method, "isMonitoring") == 0 ||
      strcmp(method, "getState") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_error_response_new(
            "platformNotSupported",
            "Linux is not supported yet for audio_monitor.",
            nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void audio_monitor_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(audio_monitor_plugin_parent_class)->dispose(object);
}

static void audio_monitor_plugin_class_init(AudioMonitorPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = audio_monitor_plugin_dispose;
}

static void audio_monitor_plugin_init(AudioMonitorPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  AudioMonitorPlugin* plugin = AUDIO_MONITOR_PLUGIN(user_data);
  audio_monitor_plugin_handle_method_call(plugin, method_call);
}

void audio_monitor_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  AudioMonitorPlugin* plugin = AUDIO_MONITOR_PLUGIN(
      g_object_new(audio_monitor_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "audio_monitor",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
