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
    @State private var showLanguageSettings = false
    
    var body: some View {
        ZStack {
            // AR View
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
                .environmentObject(appViewModel)
                .environmentObject(arViewModel)
            
            // Bottom Control Panel
            VStack {
                Spacer()
                
                if appViewModel.appState == .ready {
                    bottomControlPanel
                }
            }
            
            // Side Control Panel
            HStack {
                Spacer()
                
                if appViewModel.appState == .ready {
                    sideControlPanel
                }
            }
        }
        // Modal Sheets - Alttan açılan menüler
        .sheet(isPresented: $showUnitPicker) {
            UnitPickerView(isPresented: $showUnitPicker)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings, showLanguageSettings: $showLanguageSettings)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(isPresented: $showHistory)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showLanguageSettings) {
            LanguageSettingsView(isPresented: $showLanguageSettings)
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
            
            // Start Measurement Button
            Button(action: {
                appViewModel.startMeasuring()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.blue))
                        .frame(width: 70, height: 70)
                        .shadow(radius: 5)
                    
                    Image(systemName: "ruler.fill")
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
                    Text("history".localized)
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
            
            // Reset AR Session
            Button(action: {
                arViewModel.resetARSession()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 22))
                    .frame(width: 50, height: 50)
                    .background(Color(UIColor.black).opacity(0.7))
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
            }
            
            // Help Button
            Button(action: {
                appViewModel.isShowingMeasurementTutorial = true
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
        
        // Setup and start AR view
        arViewModel.setupARView(arView)
        appViewModel.startSession(arView: arView)
        
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
        // When SwiftUI view updates - avoid direct state changes here
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
        // İşlem kilidini önlemek için işlem bayrağı
        private var isProcessingTap = false
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            // Eğer zaten bir işlem yapılıyorsa, yeni dokunmayı işleme alma
            guard !isProcessingTap else { return }
            guard let arView = gesture.view as? ARView else { return }
            
            // Dokunma noktasını lokal olarak al
            let touchLocation = gesture.location(in: arView)
            
            // İşlem bayrağını ayarla
            isProcessingTap = true
            
            // Ray-casting işlemini arka planda yap
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    DispatchQueue.main.async {
                        self?.isProcessingTap = false
                    }
                    return
                }
                
                // Önemli: world position'u lokal olarak tut
                var worldPosition: SIMD3<Float>? = nil
                if let position = self.parent.arViewModel.performRaycast(at: touchLocation) {
                    worldPosition = position
                }
                
                // UI güncellemelerini ana thread'e taşı
                DispatchQueue.main.async {
                    if let position = worldPosition {
                        // State'e göre işlemleri gerçekleştir
                        switch self.parent.appViewModel.appState {
                        case .placingStartPoint:
                            self.parent.appViewModel.setStartPoint(position)
                        case .placingEndPoint:
                            self.parent.appViewModel.setEndPoint(position)
                        default:
                            break
                        }
                    }
                    
                    // İşlem tamamlandı, bayrağı sıfırla
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
            .navigationTitle("select_unit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("cancel".localized)
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
            return "meter".localized
        case .centimeters:
            return "centimeter".localized
        case .inches:
            return "inch".localized
        case .feet:
            return "foot".localized
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Binding var isPresented: Bool
    @Binding var showLanguageSettings: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("haptic_feedback".localized, isOn: $appViewModel.hapticFeedbackEnabled)
                        .onChange(of: appViewModel.hapticFeedbackEnabled) { _ in
                            appViewModel.toggleHapticFeedback()
                        }
                    
                    Toggle("show_guide_points".localized, isOn: $appViewModel.showGuidePoints)
                        .onChange(of: appViewModel.showGuidePoints) { _ in
                            appViewModel.toggleGuidePoints()
                        }
                }
                
                Section {
                    Button(action: {
                        appViewModel.isShowingMeasurementTutorial = true
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("show_tutorial".localized, systemImage: "questionmark.circle")
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showLanguageSettings = true
                        }
                    }) {
                        Label("Language Settings", systemImage: "globe")
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text("version".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("settings".localized)
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

// MARK: - Language Settings View
struct LanguageSettingsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) var presentationMode
    
    let languages = [
        ("English", "en"),
        ("Türkçe", "tr")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.1) { language in
                    Button(action: {
                        appViewModel.setLanguage(language.1)
                    }) {
                        HStack {
                            Text(language.0)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if appViewModel.localizationManager.currentLanguage == language.1 {
                                Image(systemName: "checkmark")
                                .foregroundColor(Color(UIColor.blue))
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Language")
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
        .presentationDetents([.medium])
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
                        Text("no_measurements".localized)
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
            .navigationTitle("measurement_history".localized)
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
