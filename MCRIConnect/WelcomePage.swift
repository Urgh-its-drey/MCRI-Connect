//
//  ContentView.swift
//  MCRIConnect
//
//  Created by Chapo on 10/29/26.
//

import SwiftUI

struct WelcomePage: View {
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Image("MatterBackgroundImage")
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                        .accessibilityHidden(true)
                    
                    AppTheme.navy.opacity(0.35)
                    
                    LinearGradient(
                        colors: [
                            AppTheme.navy.opacity(0.50),
                            AppTheme.navy.opacity(0.50),

                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    VStack(spacing: 20) {
                        logo
                            .frame(maxWidth: .infinity)
                            .padding(.top, geometry.size.height * 0.25)
                        
                        Spacer(minLength: 12)
                        
                        VStack(alignment: .center, spacing: 14) {
                            Text("YOUR FUTURE STARTS HERE")
                                .font(.headline.weight(.heavy))
                                .tracking(3)
                                .foregroundStyle(AppTheme.orange)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                            
                            Text(
                                "Discover internships that match your skills, interests, and ambitions."
                            )
                            .font(.callout)
                            .foregroundStyle(AppTheme.white.opacity(0.85))
                            .lineSpacing(4)
                            .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        NavigationLink {
                            AuthView()
                        } label: {
                            HStack {
                                Spacer()
                                
                                Text("Get Started")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .font(.headline)
                            }
                            .foregroundStyle(AppTheme.navy)
                            .padding(20)
                            .background(
                                AppTheme.orange,
                                in: RoundedRectangle(
                                    cornerRadius: 18
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(AppTheme.navy, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(28)
                    .frame(maxWidth: 500)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .safeAreaPadding(.bottom)
                }
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(AppTheme.blue)
        .preferredColorScheme(.dark)
    }
    
    private var logo: some View {
        VStack(spacing: 14) {
            Image("MatterLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
            
            Text("Matter Connect")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Matter Connect")
    }
}

#Preview {
    WelcomePage()
}

