#include <windows.h>
#include <mmdeviceapi.h>
#include <propidl.h>
#include <propsys.h>
#include <functiondiscoverykeys_devpkey.h>

#include <iomanip>
#include <iostream>
#include <optional>
#include <sstream>
#include <string>

namespace {

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
  std::string result(size_needed, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                      result.data(), size_needed, nullptr, nullptr);
  return result;
}

std::string GuidToString(REFGUID guid) {
  LPOLESTR guid_string = nullptr;
  if (FAILED(StringFromCLSID(guid, &guid_string)) || guid_string == nullptr) {
    return "{}";
  }

  std::wstring wide_value(guid_string);
  CoTaskMemFree(guid_string);
  return WideToUtf8(wide_value);
}

std::string PropertyKeyToString(const PROPERTYKEY& key) {
  std::ostringstream stream;
  stream << GuidToString(key.fmtid) << "," << key.pid;
  return stream.str();
}

std::string PropVariantToString(const PROPVARIANT& value) {
  std::ostringstream stream;
  stream << "vt=" << value.vt << " ";

  switch (value.vt) {
    case VT_EMPTY:
      stream << "<empty>";
      break;
    case VT_NULL:
      stream << "<null>";
      break;
    case VT_BOOL:
      stream << (value.boolVal == VARIANT_TRUE ? "true" : "false");
      break;
    case VT_UI4:
      stream << value.ulVal;
      break;
    case VT_LPWSTR:
      stream << (value.pwszVal == nullptr ? "" : WideToUtf8(value.pwszVal));
      break;
    default:
      stream << "<unsupported>";
      break;
  }

  return stream.str();
}

void DumpDevice(IMMDevice* device) {
  LPWSTR device_id = nullptr;
  if (FAILED(device->GetId(&device_id)) || device_id == nullptr) {
    return;
  }

  DWORD state = 0;
  device->GetState(&state);

  IPropertyStore* property_store = nullptr;
  if (FAILED(device->OpenPropertyStore(STGM_READ, &property_store)) ||
      property_store == nullptr) {
    CoTaskMemFree(device_id);
    return;
  }

  PROPVARIANT friendly_name;
  PropVariantInit(&friendly_name);
  property_store->GetValue(PKEY_Device_FriendlyName, &friendly_name);

  std::cout << "Device: " << WideToUtf8(device_id) << "\n";
  std::cout << "Name: "
            << (friendly_name.vt == VT_LPWSTR && friendly_name.pwszVal != nullptr
                    ? WideToUtf8(friendly_name.pwszVal)
                    : "<unknown>")
            << "\n";
  std::cout << "State: " << state << "\n";

  DWORD property_count = 0;
  if (SUCCEEDED(property_store->GetCount(&property_count))) {
    for (DWORD index = 0; index < property_count; ++index) {
      PROPERTYKEY key;
      if (FAILED(property_store->GetAt(index, &key))) {
        continue;
      }

      PROPVARIANT value;
      PropVariantInit(&value);
      if (SUCCEEDED(property_store->GetValue(key, &value))) {
        std::cout << "  " << PropertyKeyToString(key) << " = "
                  << PropVariantToString(value) << "\n";
      }
      PropVariantClear(&value);
    }
  }

  std::cout << "\n";
  PropVariantClear(&friendly_name);
  property_store->Release();
  CoTaskMemFree(device_id);
}

void DumpFlow(EDataFlow flow) {
  IMMDeviceEnumerator* enumerator = nullptr;
  if (FAILED(CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                              IID_PPV_ARGS(&enumerator))) ||
      enumerator == nullptr) {
    return;
  }

  IMMDeviceCollection* collection = nullptr;
  if (FAILED(
          enumerator->EnumAudioEndpoints(flow, DEVICE_STATEMASK_ALL, &collection)) ||
      collection == nullptr) {
    enumerator->Release();
    return;
  }

  UINT count = 0;
  if (SUCCEEDED(collection->GetCount(&count))) {
    for (UINT index = 0; index < count; ++index) {
      IMMDevice* device = nullptr;
      if (SUCCEEDED(collection->Item(index, &device)) && device != nullptr) {
        DumpDevice(device);
        device->Release();
      }
    }
  }

  collection->Release();
  enumerator->Release();
}

}  // namespace

int main() {
  ScopedCoInitialize co_initialize;
  if (!co_initialize.IsUsable()) {
    std::cerr << "Unable to initialize COM.\n";
    return 1;
  }

  std::cout << "=== Capture Endpoints ===\n";
  DumpFlow(eCapture);
  std::cout << "=== Render Endpoints ===\n";
  DumpFlow(eRender);
  return 0;
}
