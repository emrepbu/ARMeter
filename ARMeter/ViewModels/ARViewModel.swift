//
//  ARViewModel.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import Foundation
import RealityKit
import ARKit
import Combine
import SwiftUI
import Metal

// Inherit from NSObject to comply with NSObjectProtocol needed for ARSessionDelegate
class ARViewModel: NSObject, ObservableObject {
    // AR View reference
    @Published var arView: ARView?
    
    // AR Session status
    @Published var isTracking = false
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var planeDetectionStatus: String = "Searching for surfaces..."
    @Published var raycastResult: ARRaycastResult?
    
    // Distance measurement values
    @Published var currentRaycastPosition: SIMD3<Float>?
    
    // AR Configuration
    private var configuration = ARWorldTrackingConfiguration()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init() // Call NSObject's initializer
        setupConfiguration()
        
    }
    
    // MARK: - AR Configuration
    
    private func setupConfiguration() {
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        // Preload basic materials to address "Could not resolve material" errors
        precacheARResources()
        
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) else {
            return
        }
        
        // Add person segmentation with depth detection if device supports it
        configuration.frameSemantics.insert(.personSegmentationWithDepth)
    }
    
    private func precacheARResources() {
        // Create basic entities to initialize material caches
        let _ = ModelEntity()
        let _ = AnchorEntity()
        
        // Force load common materials
        let _ = SimpleMaterial(color: .red, roughness: 0.5, isMetallic: false)
        let _ = SimpleMaterial(color: .green, roughness: 0.5, isMetallic: false)
        let _ = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: false)
    }
    
    // MARK: - AR Session Management
    
    func setupARView(_ view: ARView) {
        // Defer @Published property update to avoid view update conflicts
        DispatchQueue.main.async { [weak self] in
            self?.arView = view
        }
        
        // Optimize AR View
        view.renderOptions = [.disablePersonOcclusion, .disableMotionBlur, .disableFaceMesh]
        view.contentScaleFactor = UIScreen.main.scale // Use correct resolution
        
        // Enable camera feed background
        view.environment.background = .cameraFeed()
        
        // Metal performance optimizations
        if let _ = MTLCreateSystemDefaultDevice() {
            // Metal device created successfully
        }
        
        // Start with AR configuration and set optimizations
        // Basic configuration to enable camera feed
        let minimalConfig = ARWorldTrackingConfiguration()
        minimalConfig.planeDetection = [.horizontal, .vertical]
        minimalConfig.environmentTexturing = .automatic
        view.session.run(minimalConfig, options: [.resetTracking, .removeExistingAnchors])
        
        // Then start full session
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            view.session.run(self.configuration, options: [])
            view.session.delegate = self
        }
        
        // Setup coaching overlay (user guidance)
        setupCoachingOverlay(for: view)
        
        // Configure AR view properties
        #if DEBUG
        view.debugOptions = [.showFeaturePoints]
        #endif
        
        // Keep ambient light estimation simple
        view.environment.lighting.intensityExponent = 1
    }
    
    func resetARSession() {
        // Reset ARSession and cleanup any environment probes
        arView?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Clean up any retained ARFrames
        autoreleasepool {
            // Force a memory cleanup
            let tempView = ARView(frame: .zero)
            tempView.session.pause()
            tempView.removeFromSuperview()
        }
    }
    
    private func setupCoachingOverlay(for view: ARView) {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = view.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = true
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            coachingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coachingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Raycast Operations
    
    func performRaycast(at point: CGPoint) -> SIMD3<Float>? {
        guard let arView = arView, let query = arView.makeRaycastQuery(from: point, 
                            allowing: .estimatedPlane, 
                            alignment: .any) else {
            return nil
        }
        
        // Get raycast results
        let results = arView.session.raycast(query)
        
        guard let firstResult = results.first else {
            return nil
        }
        
        self.raycastResult = firstResult
        let worldPosition = SIMD3<Float>(
            firstResult.worldTransform.columns.3.x,
            firstResult.worldTransform.columns.3.y,
            firstResult.worldTransform.columns.3.z
        )
        
        self.currentRaycastPosition = worldPosition
        return worldPosition
    }
    
    // MARK: - AR Content Addition
    
    func placeVirtualObject(at position: SIMD3<Float>) -> AnchorEntity {
        let anchor = AnchorEntity(world: position)
        
        // Create a virtual object
        let sphere = ModelEntity(
            mesh: .generateSphere(radius: 0.02),
            materials: [SimpleMaterial(color: .red, isMetallic: true)]
        )
        
        anchor.addChild(sphere)
        arView?.scene.addAnchor(anchor)
        
        return anchor
    }
    
    func updateTrackingStatus() {
        guard arView != nil else { return }
        
        // We're now using the trackingState that was already captured from the frame
        // This prevents holding onto the ARFrame reference
        
        switch trackingState {
        case .normal:
            self.isTracking = true
            self.planeDetectionStatus = "Ready"
        case .limited(let reason):
            self.isTracking = false
            
            switch reason {
            case .excessiveMotion:
                self.planeDetectionStatus = "Moving too fast"
            case .insufficientFeatures:
                self.planeDetectionStatus = "Not enough features in view"
            case .initializing:
                self.planeDetectionStatus = "Initializing..."
            case .relocalizing:
                self.planeDetectionStatus = "Determining location..."
            @unknown default:
                self.planeDetectionStatus = "Unknown limitation"
            }
        case .notAvailable:
            self.isTracking = false
            self.planeDetectionStatus = "Tracking unavailable"
        @unknown default:
            self.isTracking = false
            self.planeDetectionStatus = "Unknown state"
        }
    }
    
}

// MARK: - ARSessionDelegate
extension ARViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Critical: Only extract tracking state from ARFrame and immediately release
        let currentTrackingState = frame.camera.trackingState
        
        // To avoid capturing ARFrame, copy value to local variable
        // and immediately update on main thread
        DispatchQueue.main.async { [weak self, currentTrackingState] in
            guard let self = self else { return }
            self.trackingState = currentTrackingState
            self.updateTrackingStatus()
        }
        // ARFrame goes out of scope here and is automatically released
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.planeDetectionStatus = "AR session error: \(error.localizedDescription)"
            self.isTracking = false
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async {
            self.planeDetectionStatus = "AR session interrupted"
            self.isTracking = false
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            self.planeDetectionStatus = "AR session resumed"
            self.resetARSession()
        }
    }
}
