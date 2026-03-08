import SwiftUI
import CoreAudio

struct AudioSettingsView: View {
    @State private var micManager = MicrophoneManager()
    @AppStorage("audioFeedbackEnabled") private var audioFeedback = true
    @AppStorage("muteDuringDictation") private var muteDuringDictation = false

    var body: some View {
        Form {
            Section("Microphone") {
                Picker("Input Device", selection: $micManager.selectedDeviceID) {
                    Text("System Default").tag(nil as AudioDeviceID?)
                    ForEach(micManager.availableDevices) { device in
                        HStack {
                            Text(device.name)
                            if device.isBluetooth {
                                Image(systemName: "wave.3.right")
                                    .font(.caption)
                            }
                        }
                        .tag(device.id as AudioDeviceID?)
                    }
                }

                if let recommended = micManager.recommendedDevice() {
                    Text("Recommended: \(recommended.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Feedback") {
                Toggle("Audio feedback (ping/click)", isOn: $audioFeedback)
                Toggle("Mute system audio during dictation", isOn: $muteDuringDictation)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            micManager.enumerateDevices()
        }
    }
}
