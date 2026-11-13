import SwiftUI

struct AuthHeading: View {
    let symbol: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol).font(.system(size: 28, weight: .semibold))
                .foregroundStyle(WaterTheme.teal).frame(width: 64, height: 64)
                .background(WaterTheme.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 22))
            Text(title).font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AuthField<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            HStack(spacing: 12) {
                Image(systemName: symbol).foregroundStyle(WaterTheme.teal).frame(width: 20)
                content
            }.padding(16).background(.background, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.secondary.opacity(0.18)))
        }
    }
}

struct AuthPrimaryButton: View {
    let title: String
    var busy = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if busy { ProgressView().tint(.white) }
                Text(busy ? "Please wait…" : title).font(.headline)
                if !busy { Image(systemName: "arrow.right") }
            }.frame(maxWidth: .infinity).padding(.vertical, 11)
        }.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 16)).disabled(busy)
    }
}

struct AuthFeedback: View {
    @EnvironmentObject private var auth: AuthStore
    var body: some View {
        if let message = auth.message {
            Label(message, systemImage: "exclamationmark.circle")
                .font(.subheadline).foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("authenticationError")
        }
    }
}
