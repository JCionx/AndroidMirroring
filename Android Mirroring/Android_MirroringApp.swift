//
//  Android_MirroringApp.swift
//  Android Mirroring
//
//  Created by JCionx on 1/25/25.
//

import SwiftUI

@main
struct Android_MirroringApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            SettingsView()
        }
    }
}
