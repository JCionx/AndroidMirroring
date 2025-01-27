//
//  SettingsManager.swift
//  Android Mirroring
//
//  Created by JCionx on 1/26/25.
//

import Foundation

import Foundation

class SettingsManager: ObservableObject {
    @Published var resolutionX: String {
        didSet {
            UserDefaults.standard.set(resolutionX, forKey: "resolutionX")
        }
    }
    
    @Published var resolutionY: String {
        didSet {
            UserDefaults.standard.set(resolutionY, forKey: "resolutionY")
        }
    }
    
    @Published var fps: String {
        didSet {
            UserDefaults.standard.set(fps, forKey: "fps")
        }
    }
    
    @Published var codec: String {
        didSet {
            UserDefaults.standard.set(codec, forKey: "codec")
        }
    }
    
    @Published var audioEnabled: Bool {
        didSet {
            UserDefaults.standard.set(audioEnabled, forKey: "audioEnabled")
        }
    }
    
    @Published var forwardAllClicks: Bool {
        didSet {
            UserDefaults.standard.set(forwardAllClicks, forKey: "forwardAllClicks")
        }
    }
    
    @Published var gamepadPassthrough: Bool {
        didSet {
            UserDefaults.standard.set(gamepadPassthrough, forKey: "gamepadPassthrough")
        }
    }
    
    @Published var alwaysOnTop: Bool {
        didSet {
            UserDefaults.standard.set(alwaysOnTop, forKey: "alwaysOnTop")
        }
    }
    
    @Published var fullscreen: Bool {
        didSet {
            UserDefaults.standard.set(fullscreen, forKey: "fullscreen")
        }
    }
    
    @Published var moveAppToMainDisplay: Bool {
        didSet {
            UserDefaults.standard.set(moveAppToMainDisplay, forKey: "moveAppToMainDisplay")
        }
    }
    
    init() {
        let defaults: [String: Any] = [
            "audioEnabled": true,
            "forwardAllClicks": true,
            "gamepadPassthrough": false,
            "alwaysOnTop": false,
            "fullscreen": false,
            "moveAppToMainDisplay": false
        ]
        
        UserDefaults.standard.register(defaults: defaults)
        
        self.resolutionX = UserDefaults.standard.string(forKey: "resolutionX") ?? "1920"
        self.resolutionY = UserDefaults.standard.string(forKey: "resolutionY") ?? "1080"
        self.fps = UserDefaults.standard.string(forKey: "fps") ?? "60"
        self.codec = UserDefaults.standard.string(forKey: "codec") ?? "h264"
        self.audioEnabled = UserDefaults.standard.bool(forKey: "audioEnabled")
        self.forwardAllClicks = UserDefaults.standard.bool(forKey: "forwardAllClicks")
        self.gamepadPassthrough = UserDefaults.standard.bool(forKey: "gamepadPassthrough")
        self.alwaysOnTop = UserDefaults.standard.bool(forKey: "alwaysOnTop")
        self.fullscreen = UserDefaults.standard.bool(forKey: "fullscreen")
        self.moveAppToMainDisplay = UserDefaults.standard.bool(forKey: "moveAppToMainDisplay")
    }
}
