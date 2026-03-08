import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showFlowBar") private var showFlowBar = true
    @AppStorage("maxSessionMinutes") private var maxSessionMinutes = 6

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section("Flow Bar") {
                Toggle("Show Flow Bar during dictation", isOn: $showFlowBar)
            }

            Section("Session Limits") {
                Stepper("Max hands-free session: \(maxSessionMinutes) min",
                        value: $maxSessionMinutes, in: 1...30)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail - user can set manually
        }
    }
}
