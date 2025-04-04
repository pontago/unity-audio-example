//
//  iosAudioApp.swift
//  iosAudio
//
//  Created by void on 2025/04/03.
//

import SwiftUI
import AVFAudio

@main
struct iosAudioApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication
      .LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    NSLog("___application:didFinishLaunchingWithOptions")

    AVAudioSession.sharedInstance().requestRecordPermission { granted in
        }
    
    AudioManager.shared.setupAudioSession()
    
    return true
  }
}
