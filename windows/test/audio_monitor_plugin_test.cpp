#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>

#include <memory>
#include <string>

#include "audio_monitor_plugin.h"

namespace audio_monitor {
namespace test {

namespace {

using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(AudioMonitorPlugin, ReturnsPlatformNotSupportedForMonitoringCalls) {
  AudioMonitorPlugin plugin;
  std::string error_code;

  plugin.HandleMethodCall(
      MethodCall("getInputDevices", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          nullptr,
          [&error_code](const std::string& code, const std::string&,
                        const EncodableValue*) { error_code = code; },
          nullptr));

  EXPECT_EQ(error_code, "platformNotSupported");
}

}  // namespace test
}  // namespace audio_monitor
