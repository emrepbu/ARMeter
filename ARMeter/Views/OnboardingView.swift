//
//  OnboardingView.swift
//  ARMeter
//
//  Created by emre argana on 28.04.2025.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var currentPage = 0
    
    // Onboarding pages
    private var pages: [OnboardingPage] {
        return [
            OnboardingPage(
                title: "welcome_title".localized,
                description: "welcome_description".localized,
                imageName: "ruler.fill",
                backgroundColor: .blue
            ),
            
            OnboardingPage(
                title: "simple_measurements_title".localized,
                description: "simple_measurements_description".localized,
                imageName: "arrow.left.and.right",
                backgroundColor: .green
            ),
            
            OnboardingPage(
                title: "save_measurements_title".localized,
                description: "save_measurements_description".localized,
                imageName: "square.and.arrow.down",
                backgroundColor: .orange
            ),
            
            OnboardingPage(
                title: "multiple_units_title".localized,
                description: "multiple_units_description".localized,
                imageName: "ruler",
                backgroundColor: .purple
            )
        ]
    }
    
    var body: some View {
        ZStack {
            // Background color
            pages[currentPage].backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            // Content
            VStack {
                Spacer()
                
                // Icon
                Image(systemName: pages[currentPage].imageName)
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                
                // Title
                Text(pages[currentPage].title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(pages[currentPage].description)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Navigation between pages
                HStack {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Next/Start button
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            // Complete onboarding
                            appViewModel.completeOnboarding()
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "next".localized : "start".localized)
                                .fontWeight(.bold)
                            
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(pages[currentPage].backgroundColor)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(Color.white)
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            
            // Skip button
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        appViewModel.completeOnboarding()
                    }) {
                        Text("skip".localized)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
            
            // Language selection button
            VStack {
                HStack {
                    Button(action: {
                        // Toggle between languages
                        let newLang = appViewModel.localizationManager.currentLanguage == "en" ? "tr" : "en"
                        appViewModel.setLanguage(newLang)
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text(appViewModel.localizationManager.currentLanguageName)
                        }
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
}

// MARK: - Preview
#Preview {
    OnboardingView()
        .environmentObject(AppViewModel())
}
