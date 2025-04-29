//
//  ContentView.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    
    var body: some View {
        MainView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
