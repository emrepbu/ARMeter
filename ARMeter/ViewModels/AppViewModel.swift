//
//  AppViewModel.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import Foundation
import RealityKit
import ARKit
import Combine
import SwiftUI

class AppViewModel: ObservableObject {
    // App state
    @Published var appState: AppState = .onboarding
    
    // AR session status
    @Published var isSessionReady = false
    @Published var arError: String?
    
    // Measurements
    @Published var measurements: [MeasurementResult] = []
    @Published var currentMeasurement: MeasurementResult?
    @Published var startPoint: SIMD3<Float>?
    @Published var endPoint: SIMD3<Float>?
    
    // UI State
    @Published var showMeasurementResultSheet = false
    
    // Selections
    @Published var selectedUnit: MeasurementUnit = .meters
    @Published var selectedMeasurement: MeasurementResult?
    
    // User settings
    @Published var hasCompletedOnboarding = false
    @Published var isShowingMeasurementTutorial = false
    @Published var hapticFeedbackEnabled = true
    @Published var showGuidePoints = true
    
    // AR Authorization status
    @Published var arAuthorizationStatus: ARAuthorizationStatus = .notDetermined
    
    // AR Session control
    private var arSession: ARSession?
    private var arView: ARView?
    private var anchors: [AnchorEntity] = []
    
    // Material cache for performance optimization
    private static let cachedMaterials: [String: SimpleMaterial] = {
        var materials: [String: SimpleMaterial] = [:]
        
        do {
            materials["greenPoint"] = try SimpleMaterial(color: UIColor.green, roughness: 0.7, isMetallic: false)
            materials["redPoint"] = try SimpleMaterial(color: UIColor.red, roughness: 0.7, isMetallic: false)
            materials["line"] = try SimpleMaterial(color: UIColor.blue, roughness: 0.7, isMetallic: false)
            materials["textLabel"] = try SimpleMaterial(color: UIColor.white, roughness: 0.8, isMetallic: false)
            materials["textBackground"] = try SimpleMaterial(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.6), roughness: 0.8, isMetallic: false)
        } catch {
            print("Failed to create cached materials: \(error)")
            // Fallback: Create basic materials without try-catch for essential functionality
            materials["greenPoint"] = SimpleMaterial(color: UIColor.green, roughness: 0.7, isMetallic: false)
            materials["redPoint"] = SimpleMaterial(color: UIColor.red, roughness: 0.7, isMetallic: false)
            materials["line"] = SimpleMaterial(color: UIColor.blue, roughness: 0.7, isMetallic: false)
            materials["textLabel"] = SimpleMaterial(color: UIColor.white, roughness: 0.8, isMetallic: false)
            materials["textBackground"] = SimpleMaterial(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.6), roughness: 0.8, isMetallic: false)
        }
        
        return materials
    }()
    
    // Combiners
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load user preferences
        loadUserPreferences()
        
        // Check onboarding status
        checkOnboardingStatus()
        
    }
    
    // MARK: - State Management
    
    func startSession(arView: ARView) {
        self.arView = arView
        self.arSession = arView.session
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        // Materyal hatalarını azaltmak için çevre dokulandırmasını devre dışı bırakıyoruz
        config.environmentTexturing = .none
        
        // Performansı artırmak için ek optimizasyonlar
        arView.renderOptions = [.disablePersonOcclusion, .disableMotionBlur, .disableFaceMesh]
        arView.automaticallyConfigureSession = false
        
        // Daha düşük çözünürlükte çalıştır (performans için)
        arView.contentScaleFactor = 1.0
        
        // Seçici özellikleri kapat
        // Kamera görüntüsünün gösterilmesi için arka planı varsayılan olarak ayarla
        arView.environment.background = .cameraFeed()
        
        // AR session'ı güvenli bir şekilde başlat
        do {
            arSession?.run(config, options: [.removeExistingAnchors, .resetTracking])
            
            // Tüm çevre prob'larını devre dışı bırak
            arView.environment.sceneUnderstanding.options = []
            
            checkARCapabilities()
            appState = hasCompletedOnboarding ? .ready : .onboarding
        } catch {
            print("Failed to start AR session: \(error)")
            arError = "Failed to start AR session: \(error.localizedDescription)"
            appState = .error("AR session could not be started. Please restart the app.")
        }
    }
    
    private func checkARCapabilities() {
        guard ARWorldTrackingConfiguration.isSupported else {
            arError = "ARKit is not supported"
            appState = .error("This device does not have the necessary hardware for ARKit applications.")
            return
        }
        
        isSessionReady = true
    }
    
    func checkOnboardingStatus() {
        // Check if the user has completed onboarding
        if hasCompletedOnboarding {
            appState = .ready
        } else {
            appState = .onboarding
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveUserPreferences()
        appState = .ready
    }
    
    // MARK: - Measurement Operations
    
    func startMeasuring() {
        clearCurrentMeasurement()
        appState = .placingStartPoint
    }
    
    func setStartPoint(_ position: SIMD3<Float>) {
        if hapticFeedbackEnabled {
            HapticManager.shared.playSelectionFeedback()
        }
        
        self.startPoint = position
        addPointAnchor(at: position, color: UIColor.green)
        appState = .placingEndPoint
    }
    
    func setEndPoint(_ position: SIMD3<Float>) {
        if hapticFeedbackEnabled {
            HapticManager.shared.playSelectionFeedback()
        }
        
        self.endPoint = position
        addPointAnchor(at: position, color: UIColor.red)
        addLineAnchor(from: startPoint!, to: position)
        
        // Calculate distance
        if let start = startPoint {
            let distance = simd_distance(start, position)
            
            // Convert to selected unit
            let convertedDistance = selectedUnit.convert(fromMeters: distance)
            
            currentMeasurement = MeasurementResult(
                distance: convertedDistance,
                startPoint: start,
                endPoint: position,
                timestamp: Date(),
                unit: selectedUnit
            )
        }
        
        // Değişiklik burada: Modal sheet gösteriyoruz
        appState = .reviewing
        showMeasurementResultSheet = true
    }
    
    func saveMeasurement(with note: String? = nil) {
        guard var measurement = currentMeasurement else { return }
        
        measurement.note = note
        measurements.append(measurement)
        
        // Save measurement to local storage
        saveMeasurements()
        
        // Update app state after measurement
        showMeasurementResultSheet = false
        appState = .ready
    }
    
    func clearCurrentMeasurement() {
        startPoint = nil
        endPoint = nil
        currentMeasurement = nil
        removeAllAnchors()
        
        // Return user to ready state
        if appState != .onboarding {
            showMeasurementResultSheet = false
            appState = .ready
        }
    }
    
    // MARK: - AR Anchor Operations
    
    private func addPointAnchor(at position: SIMD3<Float>, color: UIColor) {
        guard let arView = arView else { return }
        
        // Bu fonksiyon zaten main thread'den çağrılıyor
        // Basit bir anchor oluştur
        let anchor = AnchorEntity(world: position)
        
        // Küçük bir küre oluştur - basit malzeme kullan
        let mesh: MeshResource
        do {
            mesh = try MeshResource.generateSphere(radius: 0.02)
        } catch {
            print("Failed to generate sphere mesh: \(error)")
            return // Graceful failure - don't crash the app
        }
        
        // Cached material kullan - color'a göre seç
        let materialKey: String
        if color == UIColor.green {
            materialKey = "greenPoint"
        } else if color == UIColor.red {
            materialKey = "redPoint"
        } else {
            // Fallback: new material (nadir durum)
            let sphere = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, roughness: 0.7, isMetallic: false)])
            anchor.addChild(sphere)
            arView.scene.addAnchor(anchor)
            self.anchors.append(anchor)
            return
        }
        
        guard let material = Self.cachedMaterials[materialKey] else { return }
        let sphere = ModelEntity(mesh: mesh, materials: [material])
        
        // Anchor'a ekle ve AR görünümüne ekle
        anchor.addChild(sphere)
        arView.scene.addAnchor(anchor)
        self.anchors.append(anchor)
    }
    
    private func addLineAnchor(from start: SIMD3<Float>, to end: SIMD3<Float>) {
        guard let arView = arView else { return }
        
        // Bu fonksiyon zaten main thread'den çağrılıyor
        let anchor = AnchorEntity(world: start)
        
        // İki nokta arasındaki mesafeyi hesapla
        let distance = simd_distance(start, end)
        
        // İki nokta arasındaki yönü belirle
        let direction = simd_normalize(end - start)
        
        // İki nokta arasındaki orta nokta
        let midPoint = (start + end) / 2
        
        // Gelecekte ortaya çıkabilecek Metal hatalarını önlemek için
        // Metalik olmayan, basit bir çizgi kullan
        let mesh: MeshResource
        do {
            mesh = try MeshResource.generateBox(size: [0.005, 0.005, distance])
        } catch {
            print("Failed to generate line mesh: \(error)")
            return // Graceful failure - don't crash the app
        }
        guard let material = Self.cachedMaterials["line"] else { return }
        let line = ModelEntity(mesh: mesh, materials: [material])
        
        // Dönüş matrisini hesapla
        // Başlangıç yönü: (0, 0, 1)
        // Hedef yön: direction
        let startDirection = SIMD3<Float>(0, 0, 1)
        let rotationAxis = simd_cross(startDirection, direction)
        let rotationAngle = acos(simd_dot(startDirection, direction))
        
        if simd_length(rotationAxis) > 0.001 {
            let rotation = simd_quaternion(rotationAngle, simd_normalize(rotationAxis))
            line.transform.rotation = rotation
        }
        
        // Çizgiyi konumlandır
        line.transform.translation = midPoint - start
        
        // Anchor'a ekle ve görünüme ekle
        anchor.addChild(line)
        arView.scene.addAnchor(anchor)
        self.anchors.append(anchor)
        
        // Add distance label at midpoint - with short delay
        // (to wait for line rendering)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.addDistanceLabel(at: midPoint, distance: distance)
        }
    }
    
    private func addDistanceLabel(at position: SIMD3<Float>, distance: Float) {
        guard let arView = arView else { return }
        
        // Do distance formatting and mesh generation on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Format distance
            let convertedDistance = self.selectedUnit.convert(fromMeters: distance)
            let formattedDistance: String
            
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            
            if let formatted = formatter.string(from: NSNumber(value: convertedDistance)) {
                formattedDistance = "\(formatted) \(self.selectedUnit.rawValue)"
            } else {
                formattedDistance = "\(convertedDistance) \(self.selectedUnit.rawValue)"
            }
            
            // Expensive text mesh generation background thread'de
            let textMesh: MeshResource
            let backgroundMesh: MeshResource
            
            do {
                textMesh = try MeshResource.generateText(
                    formattedDistance,
                    extrusionDepth: 0.001,
                    font: .systemFont(ofSize: 0.03, weight: .medium),
                    alignment: .center
                )
                
                // Background mesh generation
                backgroundMesh = try MeshResource.generatePlane(width: 0.15, height: 0.05)
            } catch {
                print("Failed to generate text/background mesh: \(error)")
                return // Graceful failure - skip label creation if mesh generation fails
            }
            
            // UI updates main thread'de
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let arView = self.arView else { return }
                
                let anchor = AnchorEntity(world: position)
                
                // Cached materials kullan
                guard let textMaterial = Self.cachedMaterials["textLabel"],
                      let backgroundMaterial = Self.cachedMaterials["textBackground"] else { return }
                
                let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
                let backgroundEntity = ModelEntity(mesh: backgroundMesh, materials: [backgroundMaterial])
                
                // Set up text
                textEntity.transform.translation = [0, 0, 0.001]
                
                // Add background
                backgroundEntity.addChild(textEntity)
                anchor.addChild(backgroundEntity)
                
                // Set rotation towards camera
                anchor.look(at: arView.cameraTransform.translation, from: position, relativeTo: nil)
                
                // Add to scene
                arView.scene.addAnchor(anchor)
                self.anchors.append(anchor)
            }
        }
    }
    
    private func removeAllAnchors() {
        guard let arView = arView else { return }
        
        // Remove anchors on the main thread to avoid threading issues
        DispatchQueue.main.async {
            for anchor in self.anchors {
                arView.scene.removeAnchor(anchor)
            }
            
            self.anchors.removeAll()
            
            // Clean up any potentially dangling environment probes
            let scene = arView.scene
            for anchor in scene.anchors {
                if anchor.name.contains("probe") || anchor.name.contains("Probe") {
                    scene.removeAnchor(anchor)
                }
            }
        }
    }
    
    // MARK: - User Preferences and Data Persistence
    
    private func loadUserPreferences() {
        if let data = UserDefaults.standard.data(forKey: "userPreferences") {
            do {
                let preferences = try JSONDecoder().decode([String: Bool].self, from: data)
                self.hasCompletedOnboarding = preferences["hasCompletedOnboarding"] ?? false
                self.hapticFeedbackEnabled = preferences["hapticFeedbackEnabled"] ?? true
                self.showGuidePoints = preferences["showGuidePoints"] ?? true
            } catch {
                print("Failed to load user preferences: \(error)")
            }
        }
        
        // Load selected measurement unit
        if let unitString = UserDefaults.standard.string(forKey: "selectedUnit"),
           let unit = MeasurementUnit(rawValue: unitString) {
            self.selectedUnit = unit
        }
        
        // Load saved measurements
        loadMeasurements()
    }
    
    private func saveUserPreferences() {
        let preferences: [String: Bool] = [
            "hasCompletedOnboarding": hasCompletedOnboarding,
            "hapticFeedbackEnabled": hapticFeedbackEnabled,
            "showGuidePoints": showGuidePoints
        ]
        
        do {
            let data = try JSONEncoder().encode(preferences)
            UserDefaults.standard.set(data, forKey: "userPreferences")
            UserDefaults.standard.set(selectedUnit.rawValue, forKey: "selectedUnit")
        } catch {
            print("Failed to save user preferences: \(error)")
        }
    }
    
    private func saveMeasurements() {
        do {
            let data = try JSONEncoder().encode(measurements)
            UserDefaults.standard.set(data, forKey: "savedMeasurements")
        } catch {
            print("Failed to save measurements: \(error)")
        }
    }
    
    private func loadMeasurements() {
        if let data = UserDefaults.standard.data(forKey: "savedMeasurements") {
            do {
                let loadedMeasurements = try JSONDecoder().decode([MeasurementResult].self, from: data)
                self.measurements = loadedMeasurements
            } catch {
                print("Failed to load measurements: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func updateSelectedUnit(_ unit: MeasurementUnit) {
        // If there's a current measurement, convert its unit
        if var measurement = currentMeasurement, measurement.unit != unit {
            // First convert to meters
            let distanceInMeters: Float
            
            switch measurement.unit {
            case .meters:
                distanceInMeters = measurement.distance
            case .centimeters:
                distanceInMeters = measurement.distance / 100
            case .inches:
                distanceInMeters = measurement.distance / 39.3701
            case .feet:
                distanceInMeters = measurement.distance / 3.28084
            }
            
            // Then convert to desired unit
            let convertedDistance = unit.convert(fromMeters: distanceInMeters)
            
            measurement.distance = convertedDistance
            measurement.unit = unit
            currentMeasurement = measurement
        }
        
        selectedUnit = unit
        saveUserPreferences()
    }
    
    func toggleHapticFeedback() {
        hapticFeedbackEnabled.toggle()
        saveUserPreferences()
    }
    
    func toggleGuidePoints() {
        showGuidePoints.toggle()
        saveUserPreferences()
    }
    
}
