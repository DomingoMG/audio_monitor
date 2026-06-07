#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <variant>

#include "audio_monitor_plugin.h"

namespace audio_monitor {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

TEST(AudioMonitorPlugin, RejectsMissingListenConfigurationArguments) {
  AudioMonitorPlugin plugin;
  std::string error_code;

  plugin.HandleMethodCall(
      MethodCall<EncodableValue>("getNativeListenConfiguration",
                                 std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<EncodableValue>>(
          nullptr,
          [&error_code](const std::string& code, const std::string&,
                        const EncodableValue*) { error_code = code; },
          nullptr));

  EXPECT_EQ(error_code, "nativeWindowsApiFailed");
}

TEST(AudioMonitorPlugin, RejectsMissingEnableArguments) {
  AudioMonitorPlugin plugin;
  std::string error_code;

  plugin.HandleMethodCall(
      MethodCall<EncodableValue>("enableNativeListen",
                                 std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<EncodableValue>>(
          nullptr,
          [&error_code](const std::string& code, const std::string&,
                        const EncodableValue*) { error_code = code; },
          nullptr));

  EXPECT_EQ(error_code, "nativeWindowsApiFailed");
}

TEST(AudioMonitorPlugin, UnknownMethodsReturnNotImplemented) {
  AudioMonitorPlugin plugin;
  bool not_implemented_called = false;

  plugin.HandleMethodCall(
      MethodCall<EncodableValue>("unknownMethod",
                                 std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<EncodableValue>>(
          nullptr, nullptr,
          [&not_implemented_called]() { not_implemented_called = true; }));

  EXPECT_TRUE(not_implemented_called);
}

}  // namespace

}  // namespace test
}  // namespace audio_monitor
