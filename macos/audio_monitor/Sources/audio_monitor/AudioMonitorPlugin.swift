import AVFoundation
import AudioToolbox
import CoreAudio
import FlutterMacOS
import os.lock

public class AudioMonitorPlugin: NSObject, FlutterPlugin {
  private var monitorSession: AudioMonitorSession?
  private var state = AudioMonitorPluginState.idle

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "audio_monitor",
      binaryMessenger: registrar.messenger
    )
    let instance = AudioMonitorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  deinit {
    monitorSession?.stop()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getInputDevices":
      handleGetDevices(type: .input, result: result)
    case "getOutputDevices":
      handleGetDevices(type: .output, result: result)
    case "start":
      handleStart(call: call, result: result)
    case "stop":
      handleStop(result: result)
    case "mute":
      handleMute(result: result)
    case "unmute":
      handleUnmute(result: result)
    case "isMuted":
      result(monitorSession?.isMuted ?? false)
    case "setVolume":
      handleSetVolume(call: call, result: result)
    case "getVolume":
      result(monitorSession?.volume ?? state.volume)
    case "isMonitoring":
      result(monitorSession != nil)
    case "getState":
      result(state.toMap())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleGetDevices(type: AudioMonitorDeviceType, result: @escaping FlutterResult) {
    do {
      let devices = try AudioDeviceRegistry.devices(for: type)
      result(devices.map { $0.toMap() })
    } catch let error as AudioMonitorPluginError {
      result(error.flutterError)
    } catch {
      result(AudioMonitorPluginError.nativeAudioError(message: error.localizedDescription).flutterError)
    }
  }

  private func handleStart(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard monitorSession == nil else {
      result(
        AudioMonitorPluginError.monitoringAlreadyActive(
          message: "Audio monitoring is already active."
        ).flutterError
      )
      return
    }

    guard
      let arguments = call.arguments as? [String: Any],
      let inputDeviceId = arguments["inputDeviceId"] as? String,
      let outputDeviceId = arguments["outputDeviceId"] as? String
    else {
      result(
        AudioMonitorPluginError.nativeAudioError(
          message: "Missing required start arguments."
        ).flutterError
      )
      return
    }

    MicrophonePermission.requestAccess { [weak self] granted in
      guard let self else { return }

      guard granted else {
        result(
          AudioMonitorPluginError.permissionDenied(
            message: "Microphone access is required for live input monitoring."
          ).flutterError
        )
        return
      }

      do {
        let inputDevice = try AudioDeviceRegistry.device(
          withIDString: inputDeviceId,
          type: .input
        )
        let outputDevice = try AudioDeviceRegistry.device(
          withIDString: outputDeviceId,
          type: .output
        )

        guard outputDevice.isDefault else {
          throw AudioMonitorPluginError.nativeAudioError(
            message: """
            macOS monitoring currently routes to the system default output device. \
            Set your target speakers as the default output and try again.
            """
          )
        }

        let session = try AudioMonitorSession(
          inputDeviceID: inputDevice.audioDeviceID,
          outputDeviceID: outputDevice.audioDeviceID
        )
        session.setVolume(self.state.volume)
        try session.start()

        self.monitorSession = session
        self.state = AudioMonitorPluginState(
          isMonitoring: true,
          isMuted: false,
          volume: session.volume,
          inputDeviceId: inputDevice.id,
          outputDeviceId: outputDevice.id
        )
        result(nil)
      } catch let error as AudioMonitorPluginError {
        result(error.flutterError)
      } catch {
        result(AudioMonitorPluginError.nativeAudioError(message: error.localizedDescription).flutterError)
      }
    }
  }

  private func handleStop(result: @escaping FlutterResult) {
    guard let session = monitorSession else {
      result(
        AudioMonitorPluginError.monitoringNotActive(
          message: "Audio monitoring is not active."
        ).flutterError
      )
      return
    }

    session.stop()
    monitorSession = nil
    state = AudioMonitorPluginState(
      isMonitoring: false,
      isMuted: false,
      volume: state.volume,
      inputDeviceId: nil,
      outputDeviceId: nil
    )
    result(nil)
  }

  private func handleMute(result: @escaping FlutterResult) {
    guard let session = monitorSession else {
      result(
        AudioMonitorPluginError.monitoringNotActive(
          message: "Audio monitoring is not active."
        ).flutterError
      )
      return
    }

    session.setMuted(true)
    state = AudioMonitorPluginState(
      isMonitoring: true,
      isMuted: true,
      volume: session.volume,
      inputDeviceId: state.inputDeviceId,
      outputDeviceId: state.outputDeviceId
    )
    result(nil)
  }

  private func handleUnmute(result: @escaping FlutterResult) {
    guard let session = monitorSession else {
      result(
        AudioMonitorPluginError.monitoringNotActive(
          message: "Audio monitoring is not active."
        ).flutterError
      )
      return
    }

    session.setMuted(false)
    state = AudioMonitorPluginState(
      isMonitoring: true,
      isMuted: false,
      volume: session.volume,
      inputDeviceId: state.inputDeviceId,
      outputDeviceId: state.outputDeviceId
    )
    result(nil)
  }

  private func handleSetVolume(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let volume = arguments["volume"] as? Double,
      volume.isFinite,
      volume >= 0.0,
      volume <= 1.0
    else {
      result(
        AudioMonitorPluginError.nativeAudioError(
          message: "Monitor volume must be a value between 0.0 and 1.0."
        ).flutterError
      )
      return
    }

    monitorSession?.setVolume(volume)
    state = AudioMonitorPluginState(
      isMonitoring: monitorSession != nil,
      isMuted: monitorSession?.isMuted ?? false,
      volume: monitorSession?.volume ?? volume,
      inputDeviceId: state.inputDeviceId,
      outputDeviceId: state.outputDeviceId
    )
    result(nil)
  }
}

private enum AudioMonitorDeviceType: String {
  case input
  case output

  var coreAudioScope: AudioObjectPropertyScope {
    switch self {
    case .input:
      return kAudioDevicePropertyScopeInput
    case .output:
      return kAudioDevicePropertyScopeOutput
    }
  }
}

private struct AudioMonitorDeviceDescriptor {
  let audioDeviceID: AudioDeviceID
  let id: String
  let name: String
  let isDefault: Bool
  let type: AudioMonitorDeviceType

  func toMap() -> [String: Any] {
    [
      "id": id,
      "name": name,
      "isDefault": isDefault,
      "type": type.rawValue
    ]
  }
}

private struct AudioMonitorPluginState {
  let isMonitoring: Bool
  let isMuted: Bool
  let volume: Double
  let inputDeviceId: String?
  let outputDeviceId: String?

  static let idle = AudioMonitorPluginState(
    isMonitoring: false,
    isMuted: false,
    volume: 1.0,
    inputDeviceId: nil,
    outputDeviceId: nil
  )

  func toMap() -> [String: Any?] {
    [
      "isMonitoring": isMonitoring,
      "isMuted": isMuted,
      "volume": volume,
      "inputDeviceId": inputDeviceId,
      "outputDeviceId": outputDeviceId
    ]
  }
}

private enum AudioMonitorPluginError: Error {
  case deviceNotFound(message: String)
  case permissionDenied(message: String)
  case monitoringAlreadyActive(message: String)
  case monitoringNotActive(message: String)
  case platformNotSupported(message: String)
  case nativeAudioError(message: String)

  var flutterError: FlutterError {
    switch self {
    case let .deviceNotFound(message):
      return FlutterError(code: "deviceNotFound", message: message, details: nil)
    case let .permissionDenied(message):
      return FlutterError(code: "permissionDenied", message: message, details: nil)
    case let .monitoringAlreadyActive(message):
      return FlutterError(code: "monitoringAlreadyActive", message: message, details: nil)
    case let .monitoringNotActive(message):
      return FlutterError(code: "monitoringNotActive", message: message, details: nil)
    case let .platformNotSupported(message):
      return FlutterError(code: "platformNotSupported", message: message, details: nil)
    case let .nativeAudioError(message):
      return FlutterError(code: "nativeAudioError", message: message, details: nil)
    }
  }
}

private enum MicrophonePermission {
  static func requestAccess(_ completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .authorized:
      completion(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .audio) { granted in
        DispatchQueue.main.async {
          completion(granted)
        }
      }
    case .denied, .restricted:
      completion(false)
    @unknown default:
      completion(false)
    }
  }
}

private enum AudioDeviceRegistry {
  static func devices(for type: AudioMonitorDeviceType) throws -> [AudioMonitorDeviceDescriptor] {
    let defaultDeviceID = try defaultDeviceID(for: type)

    return try allDeviceIDs()
      .filter { try hasChannels(deviceID: $0, scope: type.coreAudioScope) }
      .map { deviceID in
        AudioMonitorDeviceDescriptor(
          audioDeviceID: deviceID,
          id: String(deviceID),
          name: try deviceName(deviceID: deviceID),
          isDefault: deviceID == defaultDeviceID,
          type: type
        )
      }
      .sorted { lhs, rhs in
        if lhs.isDefault == rhs.isDefault {
          return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return lhs.isDefault && !rhs.isDefault
      }
  }

  static func device(
    withIDString id: String,
    type: AudioMonitorDeviceType
  ) throws -> AudioMonitorDeviceDescriptor {
    guard let rawValue = UInt32(id) else {
      throw AudioMonitorPluginError.deviceNotFound(message: "Audio device \(id) was not found.")
    }

    let deviceID = AudioDeviceID(rawValue)
    guard try hasChannels(deviceID: deviceID, scope: type.coreAudioScope) else {
      throw AudioMonitorPluginError.deviceNotFound(message: "Audio device \(id) was not found.")
    }

    return AudioMonitorDeviceDescriptor(
      audioDeviceID: deviceID,
      id: id,
      name: try deviceName(deviceID: deviceID),
      isDefault: try defaultDeviceID(for: type) == deviceID,
      type: type
    )
  }

  private static func allDeviceIDs() throws -> [AudioDeviceID] {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDevices,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )

    var dataSize: UInt32 = 0
    try withAudioObjectStatus(
      AudioObjectGetPropertyDataSize(
        AudioObjectID(kAudioObjectSystemObject),
        &address,
        0,
        nil,
        &dataSize
      ),
      message: "Unable to read audio device list size."
    )

    let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
    var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
    try withAudioObjectStatus(
      AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &address,
        0,
        nil,
        &dataSize,
        &deviceIDs
      ),
      message: "Unable to read audio device list."
    )

    return deviceIDs
  }

  private static func defaultDeviceID(for type: AudioMonitorDeviceType) throws -> AudioDeviceID {
    let selector: AudioObjectPropertySelector
    switch type {
    case .input:
      selector = kAudioHardwarePropertyDefaultInputDevice
    case .output:
      selector = kAudioHardwarePropertyDefaultOutputDevice
    }

    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )

    var deviceID = AudioDeviceID(0)
    var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
    try withAudioObjectStatus(
      AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &address,
        0,
        nil,
        &dataSize,
        &deviceID
      ),
      message: "Unable to resolve the default \(type.rawValue) device."
    )
    return deviceID
  }

  private static func deviceName(deviceID: AudioDeviceID) throws -> String {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioObjectPropertyName,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )

    var unmanagedName: Unmanaged<CFString>?
    var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    try withAudioObjectStatus(
      AudioObjectGetPropertyData(
        deviceID,
        &address,
        0,
        nil,
        &dataSize,
        &unmanagedName
      ),
      message: "Unable to read the audio device name."
    )

    guard let unmanagedName else {
      throw AudioMonitorPluginError.nativeAudioError(
        message: "Unable to read the audio device name."
      )
    }

    return unmanagedName.takeUnretainedValue() as String
  }

  private static func hasChannels(
    deviceID: AudioDeviceID,
    scope: AudioObjectPropertyScope
  ) throws -> Bool {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyStreamConfiguration,
      mScope: scope,
      mElement: kAudioObjectPropertyElementMain
    )

    var dataSize: UInt32 = 0
    try withAudioObjectStatus(
      AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize),
      message: "Unable to inspect audio device stream configuration."
    )

    let rawBuffer = UnsafeMutableRawPointer.allocate(
      byteCount: Int(dataSize),
      alignment: MemoryLayout<AudioBufferList>.alignment
    )
    defer {
      rawBuffer.deallocate()
    }

    try withAudioObjectStatus(
      AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, rawBuffer),
      message: "Unable to inspect audio device stream channels."
    )

    let bufferList = rawBuffer.assumingMemoryBound(to: AudioBufferList.self)
    let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
    let channelCount = buffers.reduce(0) { partialResult, buffer in
      partialResult + Int(buffer.mNumberChannels)
    }
    return channelCount > 0
  }
}

private final class AudioMonitorSession {
  let inputDeviceID: AudioDeviceID
  let outputDeviceID: AudioDeviceID

  private var inputUnit: AudioUnit?
  private var outputUnit: AudioUnit?
  private var captureBuffer: UnsafeMutableRawPointer?
  private var captureBufferList: UnsafeMutablePointer<AudioBufferList>?
  private var ringBuffer: ByteRingBuffer?
  private var bytesPerFrame: Int = 0
  private var streamFormat = AudioStreamBasicDescription()
  private var maximumFramesPerSlice: UInt32 = 4096
  private var targetBufferedBytes: Int = 0
  private var muted = false
  private var muteLock = os_unfair_lock_s()
  private var outputVolume = 1.0
  private var volumeLock = os_unfair_lock_s()

  init(inputDeviceID: AudioDeviceID, outputDeviceID: AudioDeviceID) throws {
    self.inputDeviceID = inputDeviceID
    self.outputDeviceID = outputDeviceID
  }

  deinit {
    stop()
  }

  func start() throws {
    if inputUnit != nil || outputUnit != nil {
      throw AudioMonitorPluginError.monitoringAlreadyActive(
        message: "Audio monitoring is already active."
      )
    }

    do {
      let inputFormat = try Self.makeClientStreamFormat(inputDeviceID: inputDeviceID)
      streamFormat = inputFormat
      bytesPerFrame = Int(inputFormat.mBytesPerFrame)

      maximumFramesPerSlice = max(
        try Self.maximumFramesPerSlice(deviceID: inputDeviceID, scope: kAudioDevicePropertyScopeInput),
        try Self.maximumFramesPerSlice(deviceID: outputDeviceID, scope: kAudioDevicePropertyScopeOutput),
        512
      )

      targetBufferedBytes = bytesPerFrame * Int(maximumFramesPerSlice) * 2
      let ringBufferCapacity = bytesPerFrame * Int(maximumFramesPerSlice) * 6
      ringBuffer = ByteRingBuffer(capacity: ringBufferCapacity)
      try allocateCaptureBuffer()

      inputUnit = try Self.makeInputUnit(
        deviceID: inputDeviceID,
        streamFormat: streamFormat,
        maximumFramesPerSlice: maximumFramesPerSlice,
        callbackRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
      )
      outputUnit = try Self.makeOutputUnit(
        deviceID: outputDeviceID,
        streamFormat: streamFormat,
        maximumFramesPerSlice: maximumFramesPerSlice,
        callbackRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
      )

      guard let inputUnit, let outputUnit else {
        throw AudioMonitorPluginError.nativeAudioError(message: "Unable to create the audio units.")
      }

      try Self.withAudioUnitStatus(AudioUnitInitialize(inputUnit), message: "Unable to initialize the input audio unit.")
      try Self.withAudioUnitStatus(AudioUnitInitialize(outputUnit), message: "Unable to initialize the output audio unit.")
      try Self.withAudioUnitStatus(AudioOutputUnitStart(outputUnit), message: "Unable to start the output audio unit.")
      try Self.withAudioUnitStatus(AudioOutputUnitStart(inputUnit), message: "Unable to start the input audio unit.")
    } catch {
      stop()
      throw error
    }
  }

  func stop() {
    if let inputUnit {
      AudioOutputUnitStop(inputUnit)
      AudioUnitUninitialize(inputUnit)
      AudioComponentInstanceDispose(inputUnit)
      self.inputUnit = nil
    }

    if let outputUnit {
      AudioOutputUnitStop(outputUnit)
      AudioUnitUninitialize(outputUnit)
      AudioComponentInstanceDispose(outputUnit)
      self.outputUnit = nil
    }

    captureBuffer?.deallocate()
    captureBuffer = nil
    captureBufferList?.deallocate()
    captureBufferList = nil
    ringBuffer = nil
    bytesPerFrame = 0
    targetBufferedBytes = 0
    setMuted(false)
    streamFormat = AudioStreamBasicDescription()
  }

  var isMuted: Bool {
    os_unfair_lock_lock(&muteLock)
    defer {
      os_unfair_lock_unlock(&muteLock)
    }
    return muted
  }

  var volume: Double {
    os_unfair_lock_lock(&volumeLock)
    defer {
      os_unfair_lock_unlock(&volumeLock)
    }
    return outputVolume
  }

  func setMuted(_ muted: Bool) {
    os_unfair_lock_lock(&muteLock)
    self.muted = muted
    os_unfair_lock_unlock(&muteLock)

    if muted {
      ringBuffer?.clear()
    }
  }

  func setVolume(_ volume: Double) {
    os_unfair_lock_lock(&volumeLock)
    outputVolume = min(max(volume, 0.0), 1.0)
    os_unfair_lock_unlock(&volumeLock)
  }

  private func allocateCaptureBuffer() throws {
    let byteCount = Int(maximumFramesPerSlice) * bytesPerFrame
    guard byteCount > 0 else {
      throw AudioMonitorPluginError.nativeAudioError(message: "Invalid capture buffer configuration.")
    }

    captureBuffer = UnsafeMutableRawPointer.allocate(
      byteCount: byteCount,
      alignment: MemoryLayout<Float32>.alignment
    )
    captureBufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
    captureBufferList?.pointee.mNumberBuffers = 1
    captureBufferList?.pointee.mBuffers = AudioBuffer(
      mNumberChannels: streamFormat.mChannelsPerFrame,
      mDataByteSize: UInt32(byteCount),
      mData: captureBuffer
    )
  }

  fileprivate func handleInput(
    ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    timeStamp: UnsafePointer<AudioTimeStamp>,
    numberFrames: UInt32
  ) -> OSStatus {
    guard
      let inputUnit,
      let ringBuffer,
      let captureBufferList
    else {
      return noErr
    }

    let byteCount = Int(numberFrames) * bytesPerFrame
    captureBufferList.pointee.mBuffers.mDataByteSize = UInt32(byteCount)

    let status = AudioUnitRender(
      inputUnit,
      ioActionFlags,
      timeStamp,
      1,
      numberFrames,
      captureBufferList
    )
    guard status == noErr else {
      return status
    }

    guard let audioData = captureBufferList.pointee.mBuffers.mData else {
      return noErr
    }

    ringBuffer.write(
      source: audioData.assumingMemoryBound(to: UInt8.self),
      count: byteCount
    )
    ringBuffer.trimToSize(targetBufferedBytes)
    return noErr
  }

  fileprivate func handleOutput(
    ioData: UnsafeMutablePointer<AudioBufferList>?,
    numberFrames: UInt32
  ) -> OSStatus {
    guard
      let ioData,
      let ringBuffer
    else {
      return noErr
    }

    if isMuted {
      ringBuffer.clear()
      let buffers = UnsafeMutableAudioBufferListPointer(ioData)
      for buffer in buffers {
        guard let data = buffer.mData else { continue }
        memset(data, 0, Int(buffer.mDataByteSize))
      }
      return noErr
    }

    let buffers = UnsafeMutableAudioBufferListPointer(ioData)
    let byteCount = Int(numberFrames) * bytesPerFrame
    let volume = self.volume

    for buffer in buffers {
      guard let data = buffer.mData else { continue }
      let filledBytes = ringBuffer.read(
        destination: data.assumingMemoryBound(to: UInt8.self),
        count: byteCount
      )

      if filledBytes < byteCount {
        memset(data.advanced(by: filledBytes), 0, byteCount - filledBytes)
      }

      if volume < 1.0, filledBytes > 0 {
        scaleSamples(
          data: data,
          byteCount: filledBytes,
          volume: Float(volume)
        )
      }
    }

    return noErr
  }

  private func scaleSamples(
    data: UnsafeMutableRawPointer,
    byteCount: Int,
    volume: Float
  ) {
    guard
      byteCount > 0,
      streamFormat.mFormatID == kAudioFormatLinearPCM,
      streamFormat.mBitsPerChannel == 32,
      (streamFormat.mFormatFlags & kAudioFormatFlagIsFloat) != 0
    else {
      return
    }

    let sampleCount = byteCount / MemoryLayout<Float>.size
    let samples = data.assumingMemoryBound(to: Float.self)
    for index in 0..<sampleCount {
      samples[index] *= volume
    }
  }

  private static func makeInputUnit(
    deviceID: AudioDeviceID,
    streamFormat: AudioStreamBasicDescription,
    maximumFramesPerSlice: UInt32,
    callbackRefCon: UnsafeMutableRawPointer
  ) throws -> AudioUnit {
    var description = AudioComponentDescription(
      componentType: kAudioUnitType_Output,
      componentSubType: kAudioUnitSubType_HALOutput,
      componentManufacturer: kAudioUnitManufacturer_Apple,
      componentFlags: 0,
      componentFlagsMask: 0
    )

    guard let component = AudioComponentFindNext(nil, &description) else {
      throw AudioMonitorPluginError.nativeAudioError(message: "Unable to locate the HAL output component.")
    }

    var audioUnit: AudioUnit?
    try withAudioUnitStatus(
      AudioComponentInstanceNew(component, &audioUnit),
      message: "Unable to create the input audio unit."
    )

    guard let audioUnit else {
      throw AudioMonitorPluginError.nativeAudioError(message: "Unable to create the input audio unit.")
    }

    var enableInput: UInt32 = 1
    var disableOutput: UInt32 = 0
    var currentDevice = deviceID
    var callback = AURenderCallbackStruct(
      inputProc: inputCallback,
      inputProcRefCon: callbackRefCon
    )
    var mutableFormat = streamFormat
    var mutableMaximumFramesPerSlice = maximumFramesPerSlice

    try withAudioUnitStatus(
      AudioUnitSetProperty(
        audioUnit,
        kAudioOutputUnitProperty_EnableIO,
        kAudioUnitScope_Input,
        1,
        &enableInput,
        UInt32(MemoryLayout<UInt32>.size)
      ),
      message: "Unable to enable input on the capture audio unit."
    )
    try withAudioUnitStatus(
      AudioUnitSetProperty(
        audioUnit,
        kAudioOutputUnitProperty_EnableIO,
        kAudioUnitScope_Output,
        0,
        &disableOutput,
        UInt32(MemoryLayout<UInt32>.size)
      ),
      message: "Unable to disable output on the capture audio unit."
    )
    try withAudioUnitStatus(
      AudioUnitSetProperty(
        audioUnit,
        kAudioOutputUnitProperty_CurrentDevice,
        kAudioUnitScope_Global,
        0,
        &currentDevice,
        UInt32(MemoryLayout<AudioDeviceID>.size)
      ),
      message: "Unable to set the selected input device."
    )
    try withAudioUnitStatus(
      AudioUnitSetProperty(
        audioUnit,
        kAudioUnitProperty_StreamFormat,
        kAudioUnitScope_Output,
        1,
        &mutableFormat,
        UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
      ),
      message: "Unable to configure the input stream format."
    )
    try withAudioUnitStatus(
      AudioUnitSetProperty(
        audioUnit,
        kAudioUnitProperty_MaximumFramesPerSlice,
        kAudioUnitScope_Global,
        0,
        &mutableMaximumFramesPerSlice,
        UInt32(MemoryLayout<UInt32>.size)
      ),
      message: "Unable to configure the input maximum frames per slice."
    )
    try withAudioUnitStatus(
      AudioUnitSetProperty(
        audioUnit,
        kAudioOutputUnitProperty_SetInputCallback,
        kAudioUnitScope_Global,
        0,
        &callback,
        UInt32(MemoryLayout<AURenderCallbackStruct>.size)
      ),
      message: "Unable to install the input callback."
    )

    return audioUnit
  }

  private static func makeOutputUnit(
    deviceID: AudioDeviceID,
    streamFormat: AudioStreamBasicDescription,
    maximumFramesPerSlice: UInt32,
    callbackRefCon: UnsafeMutableRawPointer
  ) throws -> AudioUnit {
    _ = deviceID
    var description = AudioComponentDescription(
      componentType: kAudioUnitType_Output,
      componentSubType: kAudioUnitSubType_DefaultOutput,
      componentManufacturer: kAudioUnitManufacturer_Apple,
      componentFlags: 0,
      componentFlagsMask: 0
    )

    guard let component = AudioComponentFindNext(nil, &description) else {
      throw AudioMonitorPluginError.nativeAudioError(message: "Unable to locate the default output component.")
    }

    var audioUnit: AudioUnit?
    try withAudioUnitStatus(
      AudioComponentInstanceNew(component, &audioUnit),
      message: "Unable to create the output audio unit."
    )

    guard let audioUnit else {
      throw AudioMonitorPluginError.nativeAudioError(message: "Unable to create the output audio unit.")
    }

    var callback = AURenderCallbackStruct(
      inputProc: outputCallback,
      inputProcRefCon: callbackRefCon
    )
    var mutableFormat = streamFormat
    var mutableMaximumFramesPerSlice = maximumFramesPerSlice

    try withAudioUnitStatus(
      AudioUnitSetProperty(
        audioUnit,
        kAudioUnitProperty_StreamFormat,
        kAudioUnitScope_Input,
        0,
        &mutableFormat,
        UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
      ),
      message: "Unable to configure the output stream format."
    )
    try withAudioUnitStatus(
      AudioUnitSetProperty(
        audioUnit,
        kAudioUnitProperty_MaximumFramesPerSlice,
        kAudioUnitScope_Global,
        0,
        &mutableMaximumFramesPerSlice,
        UInt32(MemoryLayout<UInt32>.size)
      ),
      message: "Unable to configure the output maximum frames per slice."
    )
    try withAudioUnitStatus(
      AudioUnitSetProperty(
        audioUnit,
        kAudioUnitProperty_SetRenderCallback,
        kAudioUnitScope_Input,
        0,
        &callback,
        UInt32(MemoryLayout<AURenderCallbackStruct>.size)
      ),
      message: "Unable to install the output callback."
    )

    return audioUnit
  }

  private static func makeClientStreamFormat(inputDeviceID: AudioDeviceID) throws -> AudioStreamBasicDescription {
    let inputFormat = try readDeviceStreamFormat(
      deviceID: inputDeviceID,
      scope: kAudioDevicePropertyScopeInput
    )
    let channelCount = max(inputFormat.mChannelsPerFrame, 1)

    return AudioStreamBasicDescription(
      mSampleRate: inputFormat.mSampleRate > 0 ? inputFormat.mSampleRate : 48_000,
      mFormatID: kAudioFormatLinearPCM,
      mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
      mBytesPerPacket: channelCount * 4,
      mFramesPerPacket: 1,
      mBytesPerFrame: channelCount * 4,
      mChannelsPerFrame: channelCount,
      mBitsPerChannel: 32,
      mReserved: 0
    )
  }

  private static func readDeviceStreamFormat(
    deviceID: AudioDeviceID,
    scope: AudioObjectPropertyScope
  ) throws -> AudioStreamBasicDescription {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyStreamFormat,
      mScope: scope,
      mElement: kAudioObjectPropertyElementMain
    )

    var format = AudioStreamBasicDescription()
    var dataSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
    try withAudioObjectStatus(
      AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &format),
      message: "Unable to read the selected audio device format."
    )
    return format
  }

  private static func maximumFramesPerSlice(
    deviceID: AudioDeviceID,
    scope: AudioObjectPropertyScope
  ) throws -> UInt32 {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyBufferFrameSize,
      mScope: scope,
      mElement: kAudioObjectPropertyElementMain
    )

    var frames: UInt32 = 0
    var dataSize = UInt32(MemoryLayout<UInt32>.size)
    try withAudioObjectStatus(
      AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &frames),
      message: "Unable to read the selected input device buffer size."
    )
    return frames
  }

  private static func withAudioUnitStatus(_ status: OSStatus, message: String) throws {
    try withAudioObjectStatus(status, message: message)
  }
}

private let inputCallback: AURenderCallback = { refCon, ioActionFlags, inTimeStamp, _, inNumberFrames, _ in
  let session = Unmanaged<AudioMonitorSession>.fromOpaque(refCon).takeUnretainedValue()
  return session.handleInput(
    ioActionFlags: ioActionFlags,
    timeStamp: inTimeStamp,
    numberFrames: inNumberFrames
  )
}

private let outputCallback: AURenderCallback = { refCon, _, _, _, inNumberFrames, ioData in
  let session = Unmanaged<AudioMonitorSession>.fromOpaque(refCon).takeUnretainedValue()
  return session.handleOutput(ioData: ioData, numberFrames: inNumberFrames)
}

private final class ByteRingBuffer {
  private let storage: UnsafeMutablePointer<UInt8>
  private let capacity: Int
  private var readIndex: Int = 0
  private var writeIndex: Int = 0
  private var availableBytes: Int = 0
  private var lock = os_unfair_lock_s()

  init(capacity: Int) {
    self.capacity = max(capacity, 1)
    self.storage = UnsafeMutablePointer<UInt8>.allocate(capacity: self.capacity)
    self.storage.initialize(repeating: 0, count: self.capacity)
  }

  deinit {
    storage.deinitialize(count: capacity)
    storage.deallocate()
  }

  func write(source: UnsafePointer<UInt8>, count: Int) {
    guard count > 0 else { return }

    os_unfair_lock_lock(&lock)
    defer {
      os_unfair_lock_unlock(&lock)
    }

    var remaining = min(count, capacity)
    let start = count - remaining

    if remaining > capacity - availableBytes {
      let overflow = remaining - (capacity - availableBytes)
      readIndex = (readIndex + overflow) % capacity
      availableBytes -= overflow
    }

    var sourceIndex = start
    while remaining > 0 {
      let chunkSize = min(remaining, capacity - writeIndex)
      storage.advanced(by: writeIndex).update(
        from: source.advanced(by: sourceIndex),
        count: chunkSize
      )
      writeIndex = (writeIndex + chunkSize) % capacity
      availableBytes += chunkSize
      sourceIndex += chunkSize
      remaining -= chunkSize
    }
  }

  func read(destination: UnsafeMutablePointer<UInt8>, count: Int) -> Int {
    guard count > 0 else { return 0 }

    os_unfair_lock_lock(&lock)
    defer {
      os_unfair_lock_unlock(&lock)
    }

    var remaining = min(count, availableBytes)
    let totalRead = remaining
    var destinationIndex = 0

    while remaining > 0 {
      let chunkSize = min(remaining, capacity - readIndex)
      destination.advanced(by: destinationIndex).update(
        from: storage.advanced(by: readIndex),
        count: chunkSize
      )
      readIndex = (readIndex + chunkSize) % capacity
      availableBytes -= chunkSize
      destinationIndex += chunkSize
      remaining -= chunkSize
    }

    return totalRead
  }

  func trimToSize(_ maxBytes: Int) {
    guard maxBytes >= 0 else { return }

    os_unfair_lock_lock(&lock)
    defer {
      os_unfair_lock_unlock(&lock)
    }

    guard availableBytes > maxBytes else { return }
    let bytesToDrop = availableBytes - maxBytes
    readIndex = (readIndex + bytesToDrop) % capacity
    availableBytes = maxBytes
  }

  func clear() {
    os_unfair_lock_lock(&lock)
    readIndex = 0
    writeIndex = 0
    availableBytes = 0
    os_unfair_lock_unlock(&lock)
  }
}

private func withAudioObjectStatus(_ status: OSStatus, message: String) throws {
  guard status == noErr else {
    throw AudioMonitorPluginError.nativeAudioError(
      message: "\(message) (OSStatus: \(status))"
    )
  }
}
