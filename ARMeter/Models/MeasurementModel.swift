//
//  MeasurementModel.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import Foundation
import RealityKit
import simd

/// Model for storing measurement results
struct MeasurementResult: Identifiable, Codable {
    var id = UUID()
    var distance: Float
    var startPoint: SIMD3<Float>
    var endPoint: SIMD3<Float>
    var timestamp: Date
    var note: String?
    var unit: MeasurementUnit
    
    var formattedDistance: String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        guard let formattedValue = formatter.string(from: NSNumber(value: distance)) else {
            return "\(distance) \(unit.rawValue)"
        }
        
        return "\(formattedValue) \(unit.rawValue)"
    }
}

/// Enum for measurement units
enum MeasurementUnit: String, CaseIterable, Codable {
    case meters = "m"
    case centimeters = "cm"
    case inches = "in"
    case feet = "ft"
    
    func convert(fromMeters value: Float) -> Float {
        switch self {
        case .meters:
            return value
        case .centimeters:
            return value * 100
        case .inches:
            return value * 39.3701
        case .feet:
            return value * 3.28084
        }
    }
}

/// Enum defining application state
enum AppState: Equatable {
    case onboarding
    case measuring
    case ready
    case placingStartPoint
    case placingEndPoint
    case reviewing
    case error(String)
}

/// Enum for checking AR authorization status
enum ARAuthorizationStatus {
    case notDetermined
    case denied
    case restricted
    case authorized
}
