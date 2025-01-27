//
//  SettingsView.swift
//  Android Mirroring
//
//  Created by JCionx on 1/26/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()

    var body: some View {
        Form {
            Section(header: Text("Video Settings")) {
                TextField("App Width", text: $settingsManager.resolutionX)
                TextField("App Height", text: $settingsManager.resolutionY)
                TextField("FPS", text: $settingsManager.fps)
                Picker("Codec", selection: $settingsManager.codec) {
                    Text("H.264").tag("h264")
                    Text("H.265").tag("h265")
                }
                .pickerStyle(MenuPickerStyle())
            }

            Section(header: Text("Audio & Controls")) {
                Toggle("Audio Enabled", isOn: $settingsManager.audioEnabled)
                Toggle("Forward all Clicks", isOn: $settingsManager.forwardAllClicks)
                Toggle("Gamepad Passthrough", isOn: $settingsManager.gamepadPassthrough)
            }

            Section(header: Text("App Behavior")) {
                Toggle("Always On Top", isOn: $settingsManager.alwaysOnTop)
                Toggle("Fullscreen", isOn: $settingsManager.fullscreen)
                Toggle("Move App to Main Display After Close", isOn: $settingsManager.moveAppToMainDisplay)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
}

#Preview {
    SettingsView()
}
