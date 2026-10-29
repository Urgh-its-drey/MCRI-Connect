

//
//  AppTheme.swift
//  MCRIConnect
//
//  Created by TAKUE on 10/29/26.
//


import SwiftUI

enum AppTheme {
    static let navy = color(0x153A55)
    static let orange = color(0xFF6825)
    static let red = color(0xC4432A)
    static let blue = color(0x159BE8)
    static let white = color(0xF7F9FA)
    static let charcoal = color(0x55595C)
    static let gray = color(0x89929A)
    static let surface = color(0x1D4865)

    private static func color(_ hex: UInt32) -> Color {
        Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

struct ThemeView: View {
    private let colors: [(name: String, hex: String, color: Color)] = [
        ("Navy", "#153A55", AppTheme.navy),
        ("Orange", "#FF6825", AppTheme.orange),
        ("Red", "#C4432A", AppTheme.red),
        ("Blue", "#159BE8", AppTheme.blue),
        ("White", "#F7F9FA", AppTheme.white),
        ("Charcoal", "#55595C", AppTheme.charcoal),
        ("Gray", "#89929A", AppTheme.gray),
        ("Surface", "#1D4865", AppTheme.surface)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("App Theme")
                    .font(.largeTitle.bold())

                Text("Your colors, together.")
                    .foregroundStyle(AppTheme.white.opacity(0.75))

                ForEach(colors, id: \.hex) { item in
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(item.color)
                            .frame(width: 52, height: 52)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        AppTheme.white.opacity(0.25),
                                        lineWidth: 1
                                    )
                            }

                        Text(item.name)
                            .font(.headline)

                        Spacer()

                        Text(item.hex)
                            .font(.system(.subheadline, design: .monospaced))
                    }
                    .padding(14)
                    .background(
                        AppTheme.surface,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }

                Text("Primary action")
                    .font(.headline)

                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(
                        AppTheme.orange,
                        in: RoundedRectangle(cornerRadius: 16)
                    )

                Label("Links and focus states", systemImage: "link")
                    .foregroundStyle(AppTheme.blue)
            }
            .padding(24)
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(AppTheme.white)
        .background(AppTheme.navy.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

