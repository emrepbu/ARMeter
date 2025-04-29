//
//  StringExtension.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import Foundation

// Extension to support localization
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
