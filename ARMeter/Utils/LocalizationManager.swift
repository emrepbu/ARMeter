//
//  LocalizationManager.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import Foundation
import Combine

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String
    
    static let shared = LocalizationManager()
    
    private init() {
        // Get the current language from user preferences or system settings
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language") {
            self.currentLanguage = savedLanguage
        } else {
            // Use the device language if no preference is saved
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            let languageCode = String(preferredLanguage.prefix(2))
            
            // Check if our app supports this language
            if ["en", "tr"].contains(languageCode) {
                self.currentLanguage = languageCode
            } else {
                // Default to English
                self.currentLanguage = "en"
            }
        }
        
        // Set the app's language
        setAppLanguage(self.currentLanguage)
    }
    
    func setAppLanguage(_ languageCode: String) {
        guard currentLanguage != languageCode else { return }
        
        // Save the selected language
        UserDefaults.standard.set(languageCode, forKey: "app_language")
        
        // Update the app bundle's preferred localization
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Update the published property
        currentLanguage = languageCode
        
        // Post notification for language change
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }
    
    // Helper function to get the current language name
    var currentLanguageName: String {
        switch currentLanguage {
        case "en": return "English"
        case "tr": return "Türkçe"
        default: return "English"
        }
    }
    
    // Helper function to get a localized string
    func localizedString(for key: String, arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(key, comment: ""), arguments: arguments)
    }
}
