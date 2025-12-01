//
//  FeedbackSurveyView.swift
//  Amped
//
//  Created by Sheraz Hussain on 23/11/2025.
//

import SwiftUI

struct FeedbackSurveyView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSource: FeedbackSource? = nil
    
    enum FeedbackSource: String, CaseIterable {
        case friends = "Friends / Family"
        case appStore = "Apple Store"
        case twitter = "X / Twitter"
        case instagram = "Instagram"
        case linkedin = "LinkedIn"
        case other = "Other"
    }
    
    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // MARK: - Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    
                    Spacer()
                    
                    Text("Feedback Survey")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                    
                    // Empty to balance layout
                    Color.clear.frame(width: 20, height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer().frame(height: 10)
                
                // MARK: - Mascot
                Image("Amped_8")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                // MARK: - Question
                Text("Where did you first hear about Amped?")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // MARK: - Options
                VStack(spacing: 14) {
                    ForEach(FeedbackSource.allCases, id: \.self) { source in
                        surveyOption(source)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 10)
                
                Spacer()
                
                // MARK: - Save Button
                Button {
                    handleSave()
                } label: {
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#18EF47"),
                                    Color(hex: "#0E8929")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .opacity(selectedSource == nil ? 0.6 : 1)
                }
                .disabled(selectedSource == nil)
                .padding(.horizontal, 32)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Option Cell
    private func surveyOption(_ source: FeedbackSource) -> some View {
        Button {
            selectedSource = source
        } label: {
            Text(source.rawValue)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    selectedSource == source ?
                    LinearGradient(
                        colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            Color(hex: "#18EF47").opacity(selectedSource == source ? 0 : 0.5),
                            lineWidth: 1
                        )
                )
                .cornerRadius(25)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Save Handler
    private func handleSave() {
        guard let selectedSource else { return }
        
        print("Survey Answer:", selectedSource.rawValue)
        
        // TODO: Send to backend or analytics here
        let body = """
        Hi,
        
        Feecback survey: \(selectedSource.rawValue)
        
        Best Regards:
        \(UserDefaults.standard.string(forKey: UserDefaultsKeys.userName) ?? "Guest User")
        """

        FeedbackEmailHelper.shared.sendFeedbackEmail(body: body)

        
        dismiss()
    }
}

#Preview {
    FeedbackSurveyView()
}
