//
//  ARMeterApp.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import SwiftUI

@main
struct ARMeterApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var arViewModel = ARViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appViewModel)
                .environmentObject(arViewModel)
        }
    }
}
