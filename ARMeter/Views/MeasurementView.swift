//
//  MeasurementView.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct MeasurementView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var arViewModel: ARViewModel
    
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showUnitPicker = false
    @State private var showSettings = false
    @State private var showHistory = false
    
    var body: some View {
        ZStack {
            // AR View - always show for camera feed
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
                .environmentObject(appViewModel)
                .environmentObject(arViewModel)
            
            // Bottom Control Panel
            VStack {
                Spacer()
                
                if appViewModel.appState == .ready ||
                   appViewModel.appState == .measuring ||
                   appViewModel.appState == .placingStartPoint ||
                   appViewModel.appState == .placingEndPoint {
                    bottomControlPanel
                }
            }
            
            // Side Control Panel
            HStack {
                Spacer()
                
                if appViewModel.appState == .ready ||
                   appViewModel.appState == .measuring ||
                   appViewModel.appState == .placingStartPoint ||
                   appViewModel.appState == .placingEndPoint {
                    sideControlPanel
                }
            }
        }
        // Modal Sheets - Bottom popup menus
        .sheet(isPresented: $showUnitPicker) {
            UnitPickerView(isPresented: $showUnitPicker)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(isPresented: $showHistory)
                .environmentObject(appViewModel)
        }
    }
    
    // MARK: - Bottom Control Panel
    private var bottomControlPanel: some View {
        HStack(spacing: 20) {
            // Unit Selector
            Button(action: {
                showUnitPicker = true
            }) {
                VStack {
                    Image(systemName: "ruler")
                        .font(.system(size: 22))
                    Text(appViewModel.selectedUnit.rawValue)
                        .font(.caption)
                }
                .frame(width: 60, height: 60)
                .background(Color(UIColor.black).opacity(0.7))
                .foregroundColor(Color.white)
                .cornerRadius(10)
            }
            
            Spacer()
            
            // Start/Stop Measurement Button
            Button(action: {
                if appViewModel.appState == .measuring ||
                   appViewModel.appState == .placingStartPoint ||
                   appViewModel.appState == .placingEndPoint {
                    appViewModel.clearCurrentMeasurement()
                    arViewModel.resetARSession()
                } else {
                    appViewModel.startMeasuring()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(appViewModel.appState == .measuring ||
                              appViewModel.appState == .placingStartPoint ||
                              appViewModel.appState == .placingEndPoint ? 
                              Color(UIColor.red) : Color(UIColor.blue))
                        .frame(width: 70, height: 70)
                        .shadow(radius: 5)
                    
                    Image(systemName: appViewModel.appState == .measuring ||
                          appViewModel.appState == .placingStartPoint ||
                          appViewModel.appState == .placingEndPoint ? 
                          "stop.fill" : "ruler.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Measurement History
            Button(action: {
                showHistory = true
            }) {
                VStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 22))
                    Text("History")
                        .font(.caption)
                }
                .frame(width: 60, height: 60)
                .background(Color(UIColor.black).opacity(0.7))
                .foregroundColor(Color.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.black).opacity(0.5))
        )
        .padding()
    }
    
    // MARK: - Side Control Panel
    private var sideControlPanel: some View {
        VStack(spacing: 20) {
            // Settings
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 22))
                    .frame(width: 50, height: 50)
                    .background(Color(UIColor.black).opacity(0.7))
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
            }
            
            // Stop/Reset Measurement (only show during measurement)
            if appViewModel.appState == .measuring ||
               appViewModel.appState == .placingStartPoint ||
               appViewModel.appState == .placingEndPoint {
                
                Button(action: {
                    appViewModel.clearCurrentMeasurement()
                    arViewModel.resetARSession()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 22))
                        .frame(width: 50, height: 50)
                        .background(Color(UIColor.orange).opacity(0.8))
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                }
            } else {
                // Clear All AR Measurements (when not measuring)
                Button(action: {
                    appViewModel.removeAllAnchors()
                    arViewModel.resetARSession()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 22))
                        .frame(width: 50, height: 50)
                        .background(Color(UIColor.black).opacity(0.7))
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                }
            }
            
            // Help Button
            Button(action: {
                appViewModel.appState = .onboarding
            }) {
                Image(systemName: "questionmark")
                    .font(.system(size: 22))
                    .frame(width: 50, height: 50)
                    .background(Color(UIColor.black).opacity(0.7))
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
            }
        }
        .padding(.trailing)
    }
}

// MARK: - AR View Container
struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var arViewModel: ARViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Enable delaysContentTouches to reduce view updates
        if let scrollView = findScrollView(in: arView) {
            scrollView.delaysContentTouches = true
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Start AR session only when user starts measuring and session not already running
        if (appViewModel.appState == .measuring ||
            appViewModel.appState == .placingStartPoint ||
            appViewModel.appState == .placingEndPoint ||
            appViewModel.appState == .reviewing) && !arViewModel.isTracking {
            
            arViewModel.setupARView(uiView)
            appViewModel.startSession(arView: uiView)
        }
    }
    
    // Helper function to find UIScrollView in view hierarchy
    private func findScrollView(in view: UIView) -> UIScrollView? {
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                return scrollView
            }
            if let found = findScrollView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ARViewContainer
        // Processing flag to prevent operation lock
        private var isProcessingTap = false
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            // If an operation is already in progress, don't handle new touches
            guard !isProcessingTap else { return }
            guard let arView = gesture.view as? ARView else { return }
            
            // Get touch location locally
            let touchLocation = gesture.location(in: arView)
            
            // Set processing flag
            isProcessingTap = true
            
            // Perform ray-casting in background
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    // If self is nil, unable to reset flag on main thread
                    // parent coordinator reference would be needed but not possible
                    // In this case the operation is already cancelled
                    return
                }
                
                // Important: keep world position locally
                var worldPosition: SIMD3<Float>? = nil
                if let position = self.parent.arViewModel.performRaycast(at: touchLocation) {
                    worldPosition = position
                }
                
                // Move UI updates to main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    if let position = worldPosition {
                        // Perform operations based on state
                        switch self.parent.appViewModel.appState {
                        case .placingStartPoint:
                            self.parent.appViewModel.setStartPoint(position)
                        case .placingEndPoint:
                            self.parent.appViewModel.setEndPoint(position)
                        default:
                            break
                        }
                    }
                    
                    // Operation completed, reset flag - now always on main thread
                    self.isProcessingTap = false
                }
            }
        }
    }
}

// MARK: - Unit Picker View
struct UnitPickerView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                List {
                    ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                        Button(action: {
                            appViewModel.updateSelectedUnit(unit)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(unitName(for: unit))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if appViewModel.selectedUnit == unit {
                                    Image(systemName: "checkmark")
                                    .foregroundColor(Color(UIColor.blue))
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Measurement Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func unitName(for unit: MeasurementUnit) -> String {
        switch unit {
        case .meters:
            return "Meter (m)"
        case .centimeters:
            return "Centimeter (cm)"
        case .inches:
            return "Inch (in)"
        case .feet:
            return "Foot (ft)"
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Haptic Feedback", isOn: $appViewModel.hapticFeedbackEnabled)
                        .onChange(of: appViewModel.hapticFeedbackEnabled) { _ in
                            appViewModel.toggleHapticFeedback()
                        }
                    
                    Toggle("Show Guide Points", isOn: $appViewModel.showGuidePoints)
                        .onChange(of: appViewModel.showGuidePoints) { _ in
                            appViewModel.toggleGuidePoints()
                        }
                }
                
                
                Section {
                    HStack {
                        Spacer()
                        Text("ARMeter v1.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}


// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Group {
                if appViewModel.measurements.isEmpty {
                    VStack {
                        Spacer()
                        Text("No saved measurements yet")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(appViewModel.measurements) { measurement in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(measurement.formattedDistance)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text(formattedDate(measurement.timestamp))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                if let note = measurement.note, !note.isEmpty {
                                    Text(note)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indices in
                            // Delete selected measurements
                            appViewModel.measurements.remove(atOffsets: indices)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Measurement History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .fontWeight(.bold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !appViewModel.measurements.isEmpty {
                        EditButton()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    MeasurementView()
        .environmentObject(AppViewModel())
        .environmentObject(ARViewModel())
}
