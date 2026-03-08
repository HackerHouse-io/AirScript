import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            AudioSettingsView()
                .tabItem { Label("Audio", systemImage: "mic") }

            ModelSettingsView()
                .tabItem { Label("Models", systemImage: "brain") }

            HotkeySettingsView()
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }

            PrivacySettingsView()
                .tabItem { Label("Privacy", systemImage: "lock.shield") }

            DictionarySettingsView()
                .tabItem { Label("Dictionary", systemImage: "textformat.abc") }

            SnippetSettingsView()
                .tabItem { Label("Snippets", systemImage: "text.insert") }

            StyleSettingsView()
                .tabItem { Label("Styles", systemImage: "paintbrush") }

            AdvancedSettingsView()
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .frame(width: 550, height: 400)
    }
}
