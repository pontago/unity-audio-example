//
//  ContentView.swift
//  iosAudio
//
//  Created by void on 2025/04/03.
//

import SwiftUI

struct ContentView: View {
  @State var db: String = "0 dB"
  private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
  
    var body: some View {
      VStack {
        Button {
          AudioManager.shared.startAudioUnit()
          
          NSLog("START Clicked.")
        } label: {
          Text("START")
        }
        .frame(width: 100, height: 40)
        .background(Color.blue)
        .foregroundColor(Color.white)
        
        Button {
          AudioManager.shared.stopAudioUnit()
          
          NSLog("STOP Clicked.")
        } label: {
          Text("STOP")
        }
        .frame(width: 100, height: 40)
        .background(Color.red)
        .foregroundColor(Color.white)
        
        Text(db).onReceive(timer) { _ in
          db = "\(AudioManager.shared.latestDb) dB"
        }
      }
      .padding()
    }
}

#Preview {
    ContentView()
}
