//
//  ContentView.swift
//  Android Mirroring
//
//  Created by JCionx on 1/25/25.
//

import SwiftUI
import Foundation


struct ContentView: View {
    
    @StateObject private var model = Model()
    @StateObject private var settingsManager = SettingsManager()
    
    private var environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin"]
    private var scrcpy_options: [String] {
        return [
            "--window-title=Android Mirroring",
            "--max-fps=\(settingsManager.fps)",
            "--video-codec=\(settingsManager.codec)",
            settingsManager.audioEnabled ? "" : "--no-audio",
            settingsManager.forwardAllClicks ? "--mouse-bind=++++" : "",
            settingsManager.gamepadPassthrough ? "--gamepad=uhid" : "--gamepad=disabled",
            settingsManager.alwaysOnTop ? "--always-on-top" : "",
            settingsManager.fullscreen ? "--fullscreen" : "",
        ]
        .compactMap { $0.isEmpty ? nil : $0 }
    }
    
    private var scrcpy_app_options: [String] {
        return [
            "--new-display=\(settingsManager.resolutionX)x\(settingsManager.resolutionY)",
            settingsManager.moveAppToMainDisplay ? "--no-vd-destroy-content" : "",
            "--no-vd-system-decorations"
        ]
        .compactMap { $0.isEmpty ? nil : $0 }
    }

    @State private var selectedItem: SelectedItem? = nil
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                Section("Devices") {
                    ForEach($model.devices.filter { $device in
                        searchText.isEmpty || device.name.lowercased().contains(searchText.lowercased())
                    }) { $device in
                        Label(device.name, systemImage: device.type == 0 ? "cable.connector" : "wifi")
                            .tag(SelectedItem.device(device))
                    }
                }
                ForEach(model.devices) { device in
                    Section("Apps on \(device.name)") {
                        ForEach(device.apps.filter { app in
                            searchText.isEmpty || app.id.lowercased().contains(searchText.lowercased())
                        }) { app in
                            Label(app.id, systemImage: "app.fill")
                                .tag(SelectedItem.app(device: device, app: app))
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem {
                    Spacer()
                }
                ToolbarItem {
                    Button {
                        Task {
                            await model.updateDevices()
                        }
                    } label: {
                        Label("Refresh Devices", systemImage: "arrow.trianglehead.clockwise")
                    }
                }
            }
        } detail: {
            switch selectedItem {
            case .device(let device):
                HStack {
                    Button("Mirror screen") {
                        mirrorScreen(deviceID: device.id)
                    }
                }
                .navigationTitle(device.name)
            case .app(let device, let app):
                HStack {
                    Button("Mirror app") {
                        mirrorApp(deviceID: device.id, appID: app.id)
                    }
                }
                .navigationTitle(app.id)
            case .none:
                ContentUnavailableView {
                    Label("No selection", systemImage: "iphone")
                } description: {
                    Text("No device or app selected.")
                }
            }
                
        }
    }
    
    func mirrorApp(deviceID: String, appID: String) {
        let scrcpy = Process()
        scrcpy.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        scrcpy.environment = environment
        scrcpy.arguments = ["scrcpy", "-s", deviceID, "--start-app=\(appID)"] + scrcpy_options + scrcpy_app_options
        
        let pipe = Pipe()
        scrcpy.standardOutput = pipe // Capture the command's output
        scrcpy.standardError = nil
        
        do {
            try scrcpy.run()
            scrcpy.waitUntilExit()
        } catch {
            print("Failed to run adb command for device \(deviceID): \(error)")
        }
    }
    
    func mirrorScreen(deviceID: String) {
        let scrcpy = Process()
        scrcpy.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        scrcpy.environment = environment
        scrcpy.arguments = ["scrcpy", "-s", deviceID] + scrcpy_options
        
        let pipe = Pipe()
        scrcpy.standardOutput = pipe // Capture the command's output
        scrcpy.standardError = nil
        
        do {
            try scrcpy.run()
            scrcpy.waitUntilExit()
        } catch {
            print("Failed to run adb command for device \(deviceID): \(error)")
        }
    }
    
}

class Model: ObservableObject {
    
    private var environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin"]
    
    @MainActor
        init() {
            Task {
                await updateDevices()
            }
        }
        
    @MainActor
    func updateDevices() async {
        devices = getDeviceIDs()
    }
    
    @Published var devices: [AndroidDevice] = []
    
    func getDeviceIDs() -> [AndroidDevice] {
        let adb = Process()
        adb.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        adb.environment = environment
        adb.arguments = ["adb", "devices", "-l"]
        
        let pipe = Pipe()
        adb.standardOutput = pipe // Capture the command's output
        adb.standardError = nil
        
        do {
            try adb.run()
            adb.waitUntilExit()
        } catch {
            print("Failed to run adb command: \(error)")
            return []
        }
        
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outputData, encoding: .utf8) else {
            print("Failed to read adb output")
            return []
        }
        
        var devices = [AndroidDevice]()
        
        let lines = output.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        for line in lines {
            // Skip the header or empty lines
            if line.starts(with: "List of devices attached") || line.isEmpty {
                continue
            }
            
            let parts = line.split(separator: " ")
            guard let id = parts.first else { continue }
            
            var name = "Unknown"
            for part in parts {
                if part.starts(with: "model:") {
                    name = part.replacingOccurrences(of: "model:", with: "")
                    break
                }
            }
            
            let type = id.contains(":") || id.contains("_tcp") ? 1 : 0 // Check if the ID contains ':' to determine IP type
            let device = AndroidDevice(id: String(id), name: name, apps: [], type: type)
            devices.append(device)
        }
        
        for (index, device) in devices.enumerated() {
            devices[index].apps = fetchInstalledApps(for: device.id)
        }
        
        return devices
    }

    func fetchInstalledApps(for deviceID: String) -> [AndroidApp] {
        let adb = Process()
        adb.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        adb.environment = environment
        adb.arguments = ["adb", "-s", deviceID, "shell", "pm", "list", "packages", "-e"]
        
        let pipe = Pipe()
        adb.standardOutput = pipe // Capture the command's output
        adb.standardError = nil
        
        do {
            try adb.run()
            adb.waitUntilExit()
        } catch {
            print("Failed to run adb command for device \(deviceID): \(error)")
            return []
        }
        
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outputData, encoding: .utf8) else {
            print("Failed to read adb output for device \(deviceID)")
            return []
        }
        
        var apps = [AndroidApp]()
        let lines = output.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        for line in lines {
            if line.starts(with: "package:") {
                let appID = line.replacingOccurrences(of: "package:", with: "")
                apps.append(AndroidApp(id: appID))
            }
        }
        
        return apps
    }
}

struct AndroidDevice: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var apps: [AndroidApp] = []
    var type: Int
    
    init(id: String, name: String? = nil, apps: [AndroidApp], type: Int) {
        self.id = id
        self.name = name ?? id
        self.apps = apps
        self.type = type
    }
}

struct AndroidApp: Identifiable, Hashable, Codable {
    var id: String
}

enum SelectedItem: Hashable {
    case device(AndroidDevice)
    case app(device: AndroidDevice, app: AndroidApp)
}

#Preview {
    ContentView()
}
