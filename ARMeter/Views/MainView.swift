//
//  MainView.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import SwiftUI
import RealityKit
import ARKit

struct MainView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var arViewModel: ARViewModel
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                switch appViewModel.appState {
                case .onboarding:
                    OnboardingView()
                case .ready, .measuring, .placingStartPoint, .placingEndPoint, .reviewing:
                    MeasurementView()
                        .environmentObject(arViewModel)
                        .sheet(isPresented: $appViewModel.showMeasurementResultSheet) {
                            MeasurementResultView()
                                .environmentObject(appViewModel)
                        }
                case .error(let message):
                    ErrorView(message: message)
                }
            }
            
            // Show status messages at the top of the hierarchy
            if appViewModel.appState != .onboarding {
                StatusOverlayView()
                    .environmentObject(arViewModel)
            }
        }
        .animation(.easeInOut, value: appViewModel.appState)
    }
}

// MARK: - Status Overlay View
struct StatusOverlayView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var arViewModel: ARViewModel
    
    var body: some View {
        VStack {
            // Top status info
            HStack {
                Text(arViewModel.planeDetectionStatus)
                    .font(.subheadline)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.7))
                    )
                    .foregroundColor(.white)
                
                Spacer()
                
                // Selected unit indicator
                Text(appViewModel.selectedUnit.rawValue)
                    .font(.headline)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.7))
                    )
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.top, 50)
            
            Spacer()
            
            // Measurement instructions
            if appViewModel.appState == .placingStartPoint || 
               appViewModel.appState == .placingEndPoint {
                
                let instruction = appViewModel.appState == .placingStartPoint ?
                    "Tap to place start point" :
                    "Tap to place end point"
                
                Text(instruction)
                    .font(.headline)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.7))
                    )
                    .foregroundColor(.white)
                    .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Measurement Result View
struct MeasurementResultView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var note: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Measurement value
                Text(appViewModel.currentMeasurement?.formattedDistance ?? "")
                    .font(.system(size: 50, weight: .bold))
                    .padding(.top, 20)
                
                // Note input
                TextField("Add note (optional)", text: $note)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        appViewModel.saveMeasurement(with: note.isEmpty ? nil : note)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        appViewModel.clearCurrentMeasurement()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("Measurement Result")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    @EnvironmentObject private var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundColor(.yellow)
            
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Return application to ready state
                appViewModel.appState = .ready
            }) {
                Text("Try Again")
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 10)
        )
        .padding()
    }
}

// MARK: - Preview Providers
#Preview {
    MainView()
        .environmentObject(AppViewModel())
}
