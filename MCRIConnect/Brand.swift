import SwiftUI

enum Brand {
    static let navy = Color(red: 0.04, green: 0.22, blue: 0.35)
    static let field = Color(red: 0.10, green: 0.31, blue: 0.45)
    static let cyan = Color(red: 0.00, green: 0.62, blue: 1.00)
    static let orange = Color(red: 1.00, green: 0.37, blue: 0.12)
    static let onOrange = Color.white
    static let mutedText = Color.white.opacity(0.68)
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
