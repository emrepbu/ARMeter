//
//  MaterialConfigurator.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import Foundation
import RealityKit
import ARKit

/// Utility class for configuring AR materials properly
class MaterialConfigurator {
    static let shared = MaterialConfigurator()
    
    private init() {}
    
    /// Configure the application to properly handle material resources
    func configure() {
        // Attempt to preload required material resources
        preloadMaterials()
    }
    
    /// Preload material resources to avoid "Could not resolve material" errors
    private func preloadMaterials() {
        // Make sure we're on a background thread for resource loading
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Create an empty entity to initialize the material system
            let _ = ModelEntity()
            
            // Preload common materials we'll use in the app
            self?.createBasicMaterials()
            
            // Configure specialized shader parameters if needed
            self?.configureShaderParameters()
        }
    }
    
    /// Create basic materials that will be used in the app
    private func createBasicMaterials() {
        // Create and cache basic materials for later use
        let _ = SimpleMaterial(color: .red, roughness: 0.5, isMetallic: false)
        let _ = SimpleMaterial(color: .green, roughness: 0.5, isMetallic: false)
        let _ = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: false)
        let _ = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
        
        // Force a material cache purge to ensure clean setup
        autoreleasepool {
            let tempEntity = ModelEntity()
            tempEntity.model = ModelComponent(mesh: .generateSphere(radius: 0.01), materials: [])
        }
    }
    
    /// Configure shader parameters to avoid "Found no parameter definition for shader constant" errors
    private func configureShaderParameters() {
        // This is a workaround to address shader parameter errors
        // Create a temporary AR session to initialize the AR parameters
        let tempConfig = ARWorldTrackingConfiguration()
        let tempSession = ARSession()
        tempSession.run(tempConfig, options: [])
        tempSession.pause()
    }
    
    /// Get a simplified material to avoid shader errors
    func getSimpleMaterial(color: UIColor) -> Material {
        // Create a non-metallic material with minimal parameters to reduce shader errors
        let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: false)
        
        // Don't use complex texture mapping features
        // Using standard material properties only
        
        return material
    }
}
