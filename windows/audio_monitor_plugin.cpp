#include "audio_monitor_plugin.h"

#include <windows.h>
#include <mmdeviceapi.h>
#include <propidl.h>
#include <propsys.h>
#include <propvarutil.h>
#include <functiondiscoverykeys_devpkey.h>
#include <guiddef.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <cstring>
#include <memory>
#include <optional>
#include <string>
#include <variant>
#include <vector>

namespace audio_monitor {

namespace {

constexpr char kDefaultOutputDeviceId[] = "default";

const PROPERTYKEY PKEY_AudioMonitor_PlaybackDevice = {
    {0x24DBB0FC, 0x9311, 0x4B3D, {0x9C, 0xF0, 0x18, 0xFF, 0x15, 0x56, 0x39, 0xD4}},
    0};
const PROPERTYKEY PKEY_AudioMonitor_ListenEnabled = {
    {0x24DBB0FC, 0x9311, 0x4B3D, {0x9C, 0xF0, 0x18, 0xFF, 0x15, 0x56, 0x39, 0xD4}},
    1};

class ScopedCoInitialize {
 public:
  ScopedCoInitialize() : hr_(CoInitializeEx(nullptr, COINIT_MULTITHREADED)) {}

  ~ScopedCoInitialize() {
    if (SUCCEEDED(hr_)) {
      CoUninitialize();
    }
  }

  bool IsUsable() const { return SUCCEEDED(hr_) || hr_ == RPC_E_CHANGED_MODE; }

 private:
  HRESULT hr_;
};

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }

  const int size_needed = WideCharToMultiByte(
      CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0,
      nullptr, nullptr);
  if (size_needed <= 0) {
    return std::string();
  }

  std::string result(size_needed, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                      result.data(), size_needed, nullptr, nullptr);
  return result;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }

  const int size_needed = MultiByteToWideChar(
      CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0);
  if (size_needed <= 0) {
    return std::wstring();
  }

  std::wstring result(size_needed, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                      result.data(), size_needed);
  return result;
}

std::string DeviceStateToString(DWORD state) {
  switch (state) {
    case DEVICE_STATE_ACTIVE:
      return "active";
    case DEVICE_STATE_DISABLED:
      return "disabled";
    case DEVICE_STATE_UNPLUGGED:
      return "unplugged";
    case DEVICE_STATE_NOTPRESENT:
      return "notPresent";
    default:
      return "unknown";
  }
}

bool IsActiveState(const std::string& state) { return state == "active"; }

HRESULT CreateEnumerator(IMMDeviceEnumerator** enumerator) {
  return CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                          IID_PPV_ARGS(enumerator));
}

std::optional<std::wstring> GetDeviceId(IMMDevice* device) {
  LPWSTR device_id = nullptr;
  const HRESULT hr = device->GetId(&device_id);
  if (FAILED(hr) || device_id == nullptr) {
    return std::nullopt;
  }

  std::wstring result(device_id);
  CoTaskMemFree(device_id);
  return result;
}

std::optional<std::wstring> ReadStringProperty(
    IPropertyStore* property_store, const PROPERTYKEY& key) {
  PROPVARIANT value;
  PropVariantInit(&value);
  const HRESULT hr = property_store->GetValue(key, &value);
  if (FAILED(hr)) {
    PropVariantClear(&value);
    return std::nullopt;
  }

  std::optional<std::wstring> result;
  if (value.vt == VT_LPWSTR && value.pwszVal != nullptr) {
    result = std::wstring(value.pwszVal);
  }

  PropVariantClear(&value);
  return result;
}

std::optional<bool> ReadBoolProperty(
    IPropertyStore* property_store, const PROPERTYKEY& key) {
  PROPVARIANT value;
  PropVariantInit(&value);
  const HRESULT hr = property_store->GetValue(key, &value);
  if (FAILED(hr)) {
    PropVariantClear(&value);
    return std::nullopt;
  }

  std::optional<bool> result;
  if (value.vt == VT_BOOL) {
    result = value.boolVal == VARIANT_TRUE;
  }

  PropVariantClear(&value);
  return result;
}

bool ReadStringOrDefaultProperty(IPropertyStore* property_store,
                                 const PROPERTYKEY& key,
                                 std::optional<std::wstring>* value,
                                 bool* uses_default_output_device) {
  PROPVARIANT property_value;
  PropVariantInit(&property_value);
  const HRESULT hr = property_store->GetValue(key, &property_value);
  if (FAILED(hr)) {
    PropVariantClear(&property_value);
    return false;
  }

  *uses_default_output_device =
      property_value.vt == VT_EMPTY || property_value.vt == VT_NULL;
  if (property_value.vt == VT_LPWSTR && property_value.pwszVal != nullptr) {
    *value = std::wstring(property_value.pwszVal);
  } else {
    value->reset();
  }

  PropVariantClear(&property_value);
  return true;
}

HRESULT SetBoolProperty(IPropertyStore* property_store, const PROPERTYKEY& key,
                        bool value) {
  PROPVARIANT property_value;
  PropVariantInit(&property_value);
  property_value.vt = VT_BOOL;
  property_value.boolVal = value ? VARIANT_TRUE : VARIANT_FALSE;
  const HRESULT hr = property_store->SetValue(key, property_value);
  PropVariantClear(&property_value);
  return hr;
}

HRESULT SetStringOrEmptyProperty(
    IPropertyStore* property_store, const PROPERTYKEY& key,
    const std::optional<std::wstring>& value) {
  PROPVARIANT property_value;
  PropVariantInit(&property_value);

  if (value.has_value()) {
    property_value.vt = VT_LPWSTR;
    const size_t bytes =
        (value->size() + 1) * sizeof(std::wstring::value_type);
    property_value.pwszVal =
        static_cast<LPWSTR>(CoTaskMemAlloc(bytes));
    if (property_value.pwszVal == nullptr) {
      return E_OUTOFMEMORY;
    }
    std::memcpy(property_value.pwszVal, value->c_str(), bytes);
  } else {
    property_value.vt = VT_EMPTY;
  }

  const HRESULT hr = property_store->SetValue(key, property_value);
  PropVariantClear(&property_value);
  return hr;
}

std::optional<std::string> ResolveDeviceNameById(
    IMMDeviceEnumerator* enumerator, const std::wstring& device_id) {
  IMMDevice* device = nullptr;
  const HRESULT hr = enumerator->GetDevice(device_id.c_str(), &device);
  if (FAILED(hr) || device == nullptr) {
    return std::nullopt;
  }

  IPropertyStore* property_store = nullptr;
  const HRESULT store_hr = device->OpenPropertyStore(STGM_READ, &property_store);
  if (FAILED(store_hr) || property_store == nullptr) {
    device->Release();
    return std::nullopt;
  }

  const auto name = ReadStringProperty(property_store, PKEY_Device_FriendlyName);
  property_store->Release();
  device->Release();
  if (!name.has_value()) {
    return std::nullopt;
  }
  return WideToUtf8(*name);
}

bool ReadDefaultOutputDevice(IMMDeviceEnumerator* enumerator,
                             std::optional<std::wstring>* device_id,
                             std::optional<std::string>* device_name) {
  IMMDevice* default_device = nullptr;
  const HRESULT hr =
      enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &default_device);
  if (FAILED(hr) || default_device == nullptr) {
    device_id->reset();
    device_name->reset();
    return false;
  }

  const auto current_device_id = GetDeviceId(default_device);
  IPropertyStore* property_store = nullptr;
  const HRESULT store_hr =
      default_device->OpenPropertyStore(STGM_READ, &property_store);
  std::optional<std::wstring> friendly_name;
  if (SUCCEEDED(store_hr) && property_store != nullptr) {
    friendly_name = ReadStringProperty(property_store, PKEY_Device_FriendlyName);
    property_store->Release();
  }
  default_device->Release();

  if (current_device_id.has_value()) {
    *device_id = *current_device_id;
  } else {
    device_id->reset();
  }

  if (friendly_name.has_value()) {
    *device_name = WideToUtf8(*friendly_name);
  } else {
    device_name->reset();
  }

  return current_device_id.has_value();
}

std::vector<AudioMonitorPlugin::AudioDeviceDescriptor> EnumerateDevices(
    EDataFlow flow, std::string* error_code, std::string* error_message) {
  std::vector<AudioMonitorPlugin::AudioDeviceDescriptor> devices;

  ScopedCoInitialize co_initialize;
  if (!co_initialize.IsUsable()) {
    *error_code = "nativeWindowsApiFailed";
    *error_message = "Unable to initialize COM for Windows audio device access.";
    return devices;
  }

  IMMDeviceEnumerator* enumerator = nullptr;
  HRESULT hr = CreateEnumerator(&enumerator);
  if (FAILED(hr) || enumerator == nullptr) {
    *error_code = "nativeWindowsApiFailed";
    *error_message = "Unable to create the Windows audio device enumerator.";
    return devices;
  }

  IMMDeviceCollection* collection = nullptr;
  hr = enumerator->EnumAudioEndpoints(flow, DEVICE_STATEMASK_ALL, &collection);
  if (FAILED(hr) || collection == nullptr) {
    enumerator->Release();
    *error_code = "nativeWindowsApiFailed";
    *error_message = "Unable to enumerate Windows audio endpoints.";
    return devices;
  }

  std::optional<std::wstring> default_device_id;
  if (flow == eRender || flow == eCapture) {
    IMMDevice* default_device = nullptr;
    if (SUCCEEDED(
            enumerator->GetDefaultAudioEndpoint(flow, eConsole, &default_device)) &&
        default_device != nullptr) {
      default_device_id = GetDeviceId(default_device);
      default_device->Release();
    }
  }

  UINT count = 0;
  hr = collection->GetCount(&count);
  if (FAILED(hr)) {
    collection->Release();
    enumerator->Release();
    *error_code = "nativeWindowsApiFailed";
    *error_message = "Unable to count Windows audio endpoints.";
    return devices;
  }

  devices.reserve(count);
  for (UINT index = 0; index < count; ++index) {
    IMMDevice* device = nullptr;
    hr = collection->Item(index, &device);
    if (FAILED(hr) || device == nullptr) {
      continue;
    }

    const auto device_id = GetDeviceId(device);
    DWORD state_value = 0;
    const HRESULT state_hr = device->GetState(&state_value);

    IPropertyStore* property_store = nullptr;
    const HRESULT store_hr = device->OpenPropertyStore(STGM_READ, &property_store);
    const auto friendly_name =
        SUCCEEDED(store_hr) && property_store != nullptr
            ? ReadStringProperty(property_store, PKEY_Device_FriendlyName)
            : std::optional<std::wstring>();

    if (property_store != nullptr) {
      property_store->Release();
    }
    device->Release();

    if (!device_id.has_value() || !friendly_name.has_value() || FAILED(state_hr)) {
      continue;
    }

    devices.push_back(AudioMonitorPlugin::AudioDeviceDescriptor{
        WideToUtf8(*device_id), WideToUtf8(*friendly_name),
        default_device_id.has_value() && *device_id == *default_device_id,
        DeviceStateToString(state_value)});
  }

  collection->Release();
  enumerator->Release();
  return devices;
}

std::optional<AudioMonitorPlugin::AudioDeviceDescriptor> FindDeviceById(
    const std::vector<AudioMonitorPlugin::AudioDeviceDescriptor>& devices,
    const std::string& device_id) {
  for (const auto& device : devices) {
    if (device.id == device_id) {
      return device;
    }
  }
  return std::nullopt;
}

HRESULT OpenDevicePropertyStore(const std::wstring& device_id, DWORD mode,
                                IMMDeviceEnumerator** enumerator_out,
                                IMMDevice** device_out,
                                IPropertyStore** property_store_out) {
  *enumerator_out = nullptr;
  *device_out = nullptr;
  *property_store_out = nullptr;

  HRESULT hr = CreateEnumerator(enumerator_out);
  if (FAILED(hr) || *enumerator_out == nullptr) {
    return hr;
  }

  hr = (*enumerator_out)->GetDevice(device_id.c_str(), device_out);
  if (FAILED(hr) || *device_out == nullptr) {
    (*enumerator_out)->Release();
    *enumerator_out = nullptr;
    return FAILED(hr) ? hr : E_FAIL;
  }

  hr = (*device_out)->OpenPropertyStore(mode, property_store_out);
  if (FAILED(hr) || *property_store_out == nullptr) {
    (*device_out)->Release();
    (*enumerator_out)->Release();
    *device_out = nullptr;
    *enumerator_out = nullptr;
    return FAILED(hr) ? hr : E_FAIL;
  }

  return S_OK;
}

void ReleaseStoreResources(IMMDeviceEnumerator* enumerator, IMMDevice* device,
                           IPropertyStore* property_store) {
  if (property_store != nullptr) {
    property_store->Release();
  }
  if (device != nullptr) {
    device->Release();
  }
  if (enumerator != nullptr) {
    enumerator->Release();
  }
}

AudioMonitorPlugin::ListenConfiguration ReadListenConfigurationForDevice(
    const std::wstring& input_device_id, std::string* error_code,
    std::string* error_message) {
  AudioMonitorPlugin::ListenConfiguration configuration;

  ScopedCoInitialize co_initialize;
  if (!co_initialize.IsUsable()) {
    *error_code = "nativeWindowsApiFailed";
    *error_message = "Unable to initialize COM for Windows audio device access.";
    return configuration;
  }

  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDevice* device = nullptr;
  IPropertyStore* property_store = nullptr;
  const HRESULT hr = OpenDevicePropertyStore(input_device_id, STGM_READ,
                                             &enumerator, &device, &property_store);
  if (FAILED(hr) || property_store == nullptr) {
    *error_code = "listenConfigurationUnavailable";
    *error_message =
        "Unable to read the Windows native listen configuration for the input device.";
    return configuration;
  }

  const auto enabled =
      ReadBoolProperty(property_store, PKEY_AudioMonitor_ListenEnabled);
  configuration.enabled = enabled.value_or(false);

  std::optional<std::wstring> output_device_id;
  bool uses_default_output_device = true;
  if (!ReadStringOrDefaultProperty(property_store, PKEY_AudioMonitor_PlaybackDevice,
                                   &output_device_id,
                                   &uses_default_output_device)) {
    ReleaseStoreResources(enumerator, device, property_store);
    *error_code = "listenConfigurationUnavailable";
    *error_message =
        "Unable to read the playback target for the Windows native listen configuration.";
    return configuration;
  }

  configuration.uses_default_output_device = uses_default_output_device;
  if (output_device_id.has_value()) {
    configuration.output_device_id = WideToUtf8(*output_device_id);
    configuration.output_device_name =
        ResolveDeviceNameById(enumerator, *output_device_id);
  } else {
    std::optional<std::wstring> default_output_device_id;
    std::optional<std::string> default_output_name;
    ReadDefaultOutputDevice(enumerator, &default_output_device_id,
                            &default_output_name);
    configuration.output_device_name = default_output_name;
  }

  ReleaseStoreResources(enumerator, device, property_store);
  return configuration;
}

void MapWriteFailure(HRESULT hr, std::string* error_code,
                     std::string* error_message) {
  if (hr == E_ACCESSDENIED) {
    *error_code = "permissionDenied";
    *error_message =
        "Windows denied write access to the endpoint property store.";
    return;
  }

  *error_code = "nativeWindowsApiFailed";
  *error_message =
      "Windows failed to update the native listen configuration.";
}

bool WriteListenConfiguration(const std::wstring& input_device_id,
                              const std::optional<std::wstring>& output_device_id,
                              std::optional<bool> enabled, std::string* error_code,
                              std::string* error_message) {
  ScopedCoInitialize co_initialize;
  if (!co_initialize.IsUsable()) {
    *error_code = "nativeWindowsApiFailed";
    *error_message = "Unable to initialize COM for Windows audio device access.";
    return false;
  }

  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDevice* device = nullptr;
  IPropertyStore* property_store = nullptr;
  const HRESULT open_hr = OpenDevicePropertyStore(
      input_device_id, STGM_READWRITE, &enumerator, &device, &property_store);
  if (FAILED(open_hr) || property_store == nullptr) {
    MapWriteFailure(open_hr, error_code, error_message);
    return false;
  }

  if (output_device_id.has_value()) {
    const HRESULT output_hr = SetStringOrEmptyProperty(
        property_store, PKEY_AudioMonitor_PlaybackDevice, output_device_id);
    if (FAILED(output_hr)) {
      ReleaseStoreResources(enumerator, device, property_store);
      MapWriteFailure(output_hr, error_code, error_message);
      return false;
    }
  }

  if (enabled.has_value()) {
    const HRESULT enabled_hr = SetBoolProperty(
        property_store, PKEY_AudioMonitor_ListenEnabled, *enabled);
    if (FAILED(enabled_hr)) {
      ReleaseStoreResources(enumerator, device, property_store);
      MapWriteFailure(enabled_hr, error_code, error_message);
      return false;
    }
  }

  ReleaseStoreResources(enumerator, device, property_store);
  return true;
}

flutter::EncodableValue ToEncodableDevice(
    const AudioMonitorPlugin::AudioDeviceDescriptor& device) {
  flutter::EncodableMap map;
  map[flutter::EncodableValue("id")] = flutter::EncodableValue(device.id);
  map[flutter::EncodableValue("name")] = flutter::EncodableValue(device.name);
  map[flutter::EncodableValue("isDefault")] =
      flutter::EncodableValue(device.is_default);
  map[flutter::EncodableValue("state")] = flutter::EncodableValue(device.state);
  return flutter::EncodableValue(map);
}

bool TryGetStringArgument(const flutter::EncodableMap& map, const char* key,
                          std::string* value) {
  const auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end() || !std::holds_alternative<std::string>(it->second)) {
    return false;
  }
  *value = std::get<std::string>(it->second);
  return true;
}

}  // namespace

void AudioMonitorPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "audio_monitor",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AudioMonitorPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AudioMonitorPlugin::AudioMonitorPlugin() {}

AudioMonitorPlugin::~AudioMonitorPlugin() {}

std::vector<AudioMonitorPlugin::AudioDeviceDescriptor>
AudioMonitorPlugin::GetInputDevices(std::string* error_code,
                                    std::string* error_message) const {
  return EnumerateDevices(eCapture, error_code, error_message);
}

std::vector<AudioMonitorPlugin::AudioDeviceDescriptor>
AudioMonitorPlugin::GetOutputDevices(std::string* error_code,
                                     std::string* error_message) const {
  return EnumerateDevices(eRender, error_code, error_message);
}

bool AudioMonitorPlugin::TryGetRequiredInputDeviceId(
    const flutter::EncodableValue* arguments, std::string* input_device_id) const {
  if (arguments == nullptr ||
      !std::holds_alternative<flutter::EncodableMap>(*arguments)) {
    return false;
  }

  return TryGetStringArgument(std::get<flutter::EncodableMap>(*arguments),
                              "inputDeviceId", input_device_id);
}

bool AudioMonitorPlugin::TryGetInputAndOutputDeviceIds(
    const flutter::EncodableValue* arguments, std::string* input_device_id,
    std::string* output_device_id) const {
  if (arguments == nullptr ||
      !std::holds_alternative<flutter::EncodableMap>(*arguments)) {
    return false;
  }

  const auto& map = std::get<flutter::EncodableMap>(*arguments);
  return TryGetStringArgument(map, "inputDeviceId", input_device_id) &&
         TryGetStringArgument(map, "outputDeviceId", output_device_id);
}

flutter::EncodableValue AudioMonitorPlugin::SerializeInputDevices(
    const std::vector<AudioDeviceDescriptor>& devices) const {
  flutter::EncodableList list;
  list.reserve(devices.size());
  for (const auto& device : devices) {
    list.push_back(ToEncodableDevice(device));
  }
  return flutter::EncodableValue(list);
}

flutter::EncodableValue AudioMonitorPlugin::SerializeOutputDevices(
    const std::vector<AudioDeviceDescriptor>& devices) const {
  flutter::EncodableList list;
  list.reserve(devices.size());
  for (const auto& device : devices) {
    list.push_back(ToEncodableDevice(device));
  }
  return flutter::EncodableValue(list);
}

flutter::EncodableValue AudioMonitorPlugin::SerializeListenConfiguration(
    const ListenConfiguration& configuration) const {
  flutter::EncodableMap map;
  map[flutter::EncodableValue("enabled")] =
      flutter::EncodableValue(configuration.enabled);
  map[flutter::EncodableValue("outputDeviceId")] =
      configuration.output_device_id.has_value()
          ? flutter::EncodableValue(*configuration.output_device_id)
          : flutter::EncodableValue();
  map[flutter::EncodableValue("outputDeviceName")] =
      configuration.output_device_name.has_value()
          ? flutter::EncodableValue(*configuration.output_device_name)
          : flutter::EncodableValue();
  map[flutter::EncodableValue("usesDefaultOutputDevice")] =
      flutter::EncodableValue(configuration.uses_default_output_device);
  return flutter::EncodableValue(map);
}

void AudioMonitorPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string method_name = method_call.method_name();

  if (method_name == "getInputDevices") {
    std::string error_code;
    std::string error_message;
    const auto devices = GetInputDevices(&error_code, &error_message);
    if (!error_code.empty()) {
      result->Error(error_code, error_message);
      return;
    }
    result->Success(SerializeInputDevices(devices));
    return;
  }

  if (method_name == "getOutputDevices") {
    std::string error_code;
    std::string error_message;
    const auto devices = GetOutputDevices(&error_code, &error_message);
    if (!error_code.empty()) {
      result->Error(error_code, error_message);
      return;
    }
    result->Success(SerializeOutputDevices(devices));
    return;
  }

  if (method_name == "getNativeListenConfiguration") {
    std::string input_device_id;
    if (!TryGetRequiredInputDeviceId(method_call.arguments(), &input_device_id)) {
      result->Error("nativeWindowsApiFailed",
                    "Missing required inputDeviceId argument.");
      return;
    }

    std::string error_code;
    std::string error_message;
    const auto inputs = GetInputDevices(&error_code, &error_message);
    if (!error_code.empty()) {
      result->Error(error_code, error_message);
      return;
    }

    if (!FindDeviceById(inputs, input_device_id).has_value()) {
      result->Error("inputDeviceNotFound",
                    "The selected input device was not found.");
      return;
    }

    const auto configuration = ReadListenConfigurationForDevice(
        Utf8ToWide(input_device_id), &error_code, &error_message);
    if (!error_code.empty()) {
      result->Error(error_code, error_message);
      return;
    }

    result->Success(SerializeListenConfiguration(configuration));
    return;
  }

  if (method_name == "enableNativeListen" ||
      method_name == "setNativeListenOutputDevice") {
    std::string input_device_id;
    std::string output_device_id;
    if (!TryGetInputAndOutputDeviceIds(method_call.arguments(), &input_device_id,
                                       &output_device_id)) {
      result->Error("nativeWindowsApiFailed",
                    "Missing required enableNativeListen arguments.");
      return;
    }

    std::string error_code;
    std::string error_message;
    const auto inputs = GetInputDevices(&error_code, &error_message);
    if (!error_code.empty()) {
      result->Error(error_code, error_message);
      return;
    }

    const auto input_device = FindDeviceById(inputs, input_device_id);
    if (!input_device.has_value()) {
      result->Error("inputDeviceNotFound",
                    "The selected input device was not found.");
      return;
    }

    if (method_name == "enableNativeListen" &&
        !IsActiveState(input_device->state)) {
      result->Error("deviceNotActive",
                    "The selected input device is not active.");
      return;
    }

    std::optional<std::wstring> output_device_id_for_write;
    if (output_device_id != kDefaultOutputDeviceId) {
      const auto outputs = GetOutputDevices(&error_code, &error_message);
      if (!error_code.empty()) {
        result->Error(error_code, error_message);
        return;
      }

      const auto output_device = FindDeviceById(outputs, output_device_id);
      if (!output_device.has_value()) {
        result->Error("outputDeviceNotFound",
                      "The selected output device was not found.");
        return;
      }

      if (!IsActiveState(output_device->state)) {
        result->Error("deviceNotActive",
                      "The selected output device is not active.");
        return;
      }

      output_device_id_for_write = Utf8ToWide(output_device_id);
    }

    const std::optional<bool> enabled =
        method_name == "enableNativeListen" ? std::optional<bool>(true)
                                            : std::nullopt;
    if (!WriteListenConfiguration(Utf8ToWide(input_device_id),
                                  output_device_id_for_write, enabled,
                                  &error_code, &error_message)) {
      result->Error(error_code, error_message);
      return;
    }

    result->Success();
    return;
  }

  if (method_name == "disableNativeListen") {
    std::string input_device_id;
    if (!TryGetRequiredInputDeviceId(method_call.arguments(), &input_device_id)) {
      result->Error("nativeWindowsApiFailed",
                    "Missing required inputDeviceId argument.");
      return;
    }

    std::string error_code;
    std::string error_message;
    const auto inputs = GetInputDevices(&error_code, &error_message);
    if (!error_code.empty()) {
      result->Error(error_code, error_message);
      return;
    }

    if (!FindDeviceById(inputs, input_device_id).has_value()) {
      result->Error("inputDeviceNotFound",
                    "The selected input device was not found.");
      return;
    }

    if (!WriteListenConfiguration(Utf8ToWide(input_device_id), std::nullopt,
                                  false, &error_code, &error_message)) {
      result->Error(error_code, error_message);
      return;
    }

    result->Success();
    return;
  }

  result->NotImplemented();
}

}  // namespace audio_monitor
