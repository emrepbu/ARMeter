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
        
        materials["greenPoint"] = SimpleMaterial(color: UIColor.green, roughness: 0.7, isMetallic: false)
        materials["redPoint"] = SimpleMaterial(color: UIColor.red, roughness: 0.7, isMetallic: false)
        materials["line"] = SimpleMaterial(color: UIColor.blue, roughness: 0.7, isMetallic: false)
        materials["textLabel"] = SimpleMaterial(color: UIColor.white, roughness: 0.8, isMetallic: false)
        materials["textBackground"] = SimpleMaterial(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.6), roughness: 0.8, isMetallic: false)
        
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
        // Prevent multiple sessions from starting
        guard self.arView !== arView else { return }
        
        self.arView = arView
        self.arSession = arView.session
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        // Disable environment texturing to reduce material errors
        config.environmentTexturing = .none
        
        // Additional optimizations to improve performance
        arView.renderOptions = [.disablePersonOcclusion, .disableMotionBlur, .disableFaceMesh]
        arView.automaticallyConfigureSession = false
        
        // Run at lower resolution (for performance)
        arView.contentScaleFactor = 1.0
        
        // Disable selective features
        // Set background to default for camera feed display
        arView.environment.background = .cameraFeed()
        
        // Start AR session safely
        arSession?.run(config, options: [.removeExistingAnchors, .resetTracking])
        
        // Disable all environment probes
        arView.environment.sceneUnderstanding.options = []
        
        checkARCapabilities()
        
        // Defer @Published property update to avoid view update conflicts
        DispatchQueue.main.async { [weak self] in
            self?.appState = .ready
        }
    }
    
    private func checkARCapabilities() {
        guard ARWorldTrackingConfiguration.isSupported else {
            // Defer @Published property updates to avoid view update conflicts
            DispatchQueue.main.async { [weak self] in
                self?.arError = "ARKit is not supported"
                self?.appState = .error("This device does not have the necessary hardware for ARKit applications.")
            }
            return
        }
        
        // Defer @Published property update to avoid view update conflicts
        DispatchQueue.main.async { [weak self] in
            self?.isSessionReady = true
        }
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
        
        // Defer @Published property update to avoid view update conflicts
        DispatchQueue.main.async { [weak self] in
            self?.appState = .measuring // This will trigger AR session to start
        }
        
        // After a short delay, transition to placing start point
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.appState = .placingStartPoint
        }
    }
    
    func stopMeasuring() {
        // Clear any current measurement and return to ready state
        clearCurrentMeasurement()
        
        // Stop AR session
        arSession?.pause()
        
        // Defer @Published property update to avoid view update conflicts
        DispatchQueue.main.async { [weak self] in
            self?.appState = .ready
        }
    }
    
    func setStartPoint(_ position: SIMD3<Float>) {
        if hapticFeedbackEnabled {
            HapticManager.shared.playSelectionFeedback()
        }
        
        self.startPoint = position
        addPointAnchor(at: position, color: UIColor.green)
        
        // Defer @Published property update to avoid view update conflicts
        DispatchQueue.main.async { [weak self] in
            self?.appState = .placingEndPoint
        }
    }
    
    func setEndPoint(_ position: SIMD3<Float>) {
        if hapticFeedbackEnabled {
            HapticManager.shared.playSelectionFeedback()
        }
        
        self.endPoint = position
        addPointAnchor(at: position, color: UIColor.red)
        
        // Calculate distance and add line anchor
        guard let start = startPoint else {
            print("Error: startPoint is nil when setting endPoint")
            return
        }
        
        addLineAnchor(from: start, to: position)
        
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
        
        // Change here: Show modal sheet
        // Defer @Published property updates to avoid view update conflicts
        DispatchQueue.main.async { [weak self] in
            self?.appState = .reviewing
            self?.showMeasurementResultSheet = true
        }
    }
    
    func saveMeasurement(with note: String? = nil) {
        guard var measurement = currentMeasurement else { return }
        
        measurement.note = note
        measurements.append(measurement)
        
        // Save measurement to local storage
        saveMeasurements()
        
        // Update app state after measurement
        // Defer @Published property updates to avoid view update conflicts
        DispatchQueue.main.async { [weak self] in
            self?.showMeasurementResultSheet = false
            self?.appState = .ready
        }
    }
    
    func clearCurrentMeasurement() {
        startPoint = nil
        endPoint = nil
        currentMeasurement = nil
        removeAllAnchors()
        
        // Return user to ready state
        // Defer @Published property updates to avoid view update conflicts
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.appState != .onboarding {
                self.showMeasurementResultSheet = false
                self.appState = .ready
            }
        }
    }
    
    // MARK: - AR Anchor Operations
    
    private func addPointAnchor(at position: SIMD3<Float>, color: UIColor) {
        guard let arView = arView else { return }
        
        // This function is already called from main thread
        // Create a simple anchor
        let anchor = AnchorEntity(world: position)
        
        // Create a small sphere - use simple material
        let mesh = MeshResource.generateSphere(radius: 0.01)
        
        // Use cached material - select based on color
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
        
        // Add to anchor and add to AR view
        anchor.addChild(sphere)
        arView.scene.addAnchor(anchor)
        self.anchors.append(anchor)
    }
    
    private func addLineAnchor(from start: SIMD3<Float>, to end: SIMD3<Float>) {
        guard let arView = arView else { return }
        
        // This function is already called from main thread
        let anchor = AnchorEntity(world: start)
        
        // Calculate distance between two points
        let distance = simd_distance(start, end)
        
        // Determine direction between two points
        let direction = simd_normalize(end - start)
        
        // Midpoint between two points
        let midPoint = (start + end) / 2
        
        // To prevent potential Metal errors in the future
        // Use non-metallic, simple line
        let mesh = MeshResource.generateBox(size: [0.005, 0.005, distance])
        guard let material = Self.cachedMaterials["line"] else { return }
        let line = ModelEntity(mesh: mesh, materials: [material])
        
        // Calculate rotation matrix
        // Starting direction: (0, 0, 1)
        // Target direction: direction
        let startDirection = SIMD3<Float>(0, 0, 1)
        let rotationAxis = simd_cross(startDirection, direction)
        let rotationAngle = acos(simd_dot(startDirection, direction))
        
        if simd_length(rotationAxis) > 0.001 {
            let rotation = simd_quaternion(rotationAngle, simd_normalize(rotationAxis))
            line.transform.rotation = rotation
        }
        
        // Position the line
        line.transform.translation = midPoint - start
        
        // Add to anchor and add to view
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
        
        // Capture selectedUnit on main thread
        let currentUnit = selectedUnit
        
        // Format distance on main thread
        let convertedDistance = currentUnit.convert(fromMeters: distance)
        let formattedDistance: String
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: convertedDistance)) {
            formattedDistance = "\(formatted) \(currentUnit.rawValue)"
        } else {
            formattedDistance = "\(convertedDistance) \(currentUnit.rawValue)"
        }
        
        // Generate meshes on main thread (RealityKit requirement)
        let textMesh = MeshResource.generateText(
            formattedDistance,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.03, weight: .medium),
            alignment: .center
        )
        
        let backgroundMesh = MeshResource.generatePlane(width: 0.15, height: 0.05)
        
        // Create and add entities
        let anchor = AnchorEntity(world: position)
        
        // Use cached materials
        guard let textMaterial = Self.cachedMaterials["textLabel"],
              let backgroundMaterial = Self.cachedMaterials["textBackground"] else { return }
        
        // Create text and background entities
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        let backgroundEntity = ModelEntity(mesh: backgroundMesh, materials: [backgroundMaterial])
        
        // Set up text
        textEntity.transform.translation = [0, 0, 0.001]
        
        // Add background with text
        backgroundEntity.addChild(textEntity)
        anchor.addChild(backgroundEntity)
        
        // Set rotation towards camera
        anchor.look(at: arView.cameraTransform.translation, from: position, relativeTo: nil)
        
        // Add to scene
        arView.scene.addAnchor(anchor)
        self.anchors.append(anchor)
    }
    
    func removeAllAnchors() {
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
    
    func restoreAllMeasurements() {
        guard arView != nil else { return }
        
        // Restore all saved measurements as AR anchors
        for measurement in measurements {
            // Add start point
            addPointAnchor(at: measurement.startPoint, color: UIColor.green)
            // Add end point
            addPointAnchor(at: measurement.endPoint, color: UIColor.red)
            // Add line
            addLineAnchor(from: measurement.startPoint, to: measurement.endPoint)
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
        
        // Update AR view debug options immediately
        if let arView = arView {
            if showGuidePoints {
                arView.debugOptions = [.showFeaturePoints, .showAnchorOrigins]
            } else {
                arView.debugOptions = []
            }
        }
    }
    
}
