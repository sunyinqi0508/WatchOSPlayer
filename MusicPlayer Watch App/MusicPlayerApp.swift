//
//  MusicPlayerApp.swift
//  MusicPlayer Watch App
//
//  Created by BillSun on 3/18/23.
//

import SwiftUI
import WatchKit

@main
struct MusicPlayer_Watch_AppApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView().cornerRadius(.zero)
                .padding(.zero)
                .frame(
                    width: WKInterfaceDevice.current().screenBounds.width,
                    height: WKInterfaceDevice.current().screenBounds.height
                ).tabItem {
                    Image(systemName: "circle.fill")
                }
        }
    }
    
}
