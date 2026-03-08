import AVFoundation
import CoreAudio
import os

struct MicrophoneDevice: Identifiable {
    let id: AudioDeviceID
    let name: String
    let isBuiltIn: Bool
    let isBluetooth: Bool
}

@Observable
final class MicrophoneManager {
    var availableDevices: [MicrophoneDevice] = []
    var selectedDeviceID: AudioDeviceID?

    private let logger = Logger.audio

    func enumerateDevices() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize
        )

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize,
            &deviceIDs
        )

        availableDevices = deviceIDs.compactMap { deviceID in
            guard hasInputChannels(deviceID) else { return nil }
            let name = getDeviceName(deviceID)
            let transport = getTransportType(deviceID)
            return MicrophoneDevice(
                id: deviceID,
                name: name,
                isBuiltIn: transport == kAudioDeviceTransportTypeBuiltIn,
                isBluetooth: transport == kAudioDeviceTransportTypeBluetooth ||
                             transport == kAudioDeviceTransportTypeBluetoothLE
            )
        }

        logger.info("Found \(self.availableDevices.count) input devices")
    }

    func recommendedDevice() -> MicrophoneDevice? {
        // Prefer built-in over Bluetooth for lower latency
        availableDevices.first(where: { $0.isBuiltIn }) ?? availableDevices.first
    }

    private func hasInputChannels(_ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &dataSize)
        guard status == noErr else { return false }

        let bufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
        defer { bufferListPointer.deallocate() }

        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, bufferListPointer)

        let bufferList = UnsafeMutableAudioBufferListPointer(bufferListPointer)
        return bufferList.reduce(0) { $0 + Int($1.mNumberChannels) } > 0
    }

    private func getDeviceName(_ deviceID: AudioDeviceID) -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, &name)
        return name as String
    }

    private func getTransportType(_ deviceID: AudioDeviceID) -> UInt32 {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var transport: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, &transport)
        return transport
    }
}
