import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )

        var integer: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&integer)

        let red = Double((integer >> 16) & 0xFF) / 255.0
        let green = Double((integer >> 8) & 0xFF) / 255.0
        let blue = Double(integer & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    static let mcriNavy = Color(hex: "#153A55")
    static let mcriOrange = Color(hex: "#FF6825")
    static let mcriRed = Color(hex: "#C4432A")
    static let mcriBlue = Color(hex: "#159BE8")
    static let mcriWhite = Color(hex: "#F7F9FA")
    static let mcriCharcoal = Color(hex: "#55595C")
    static let mcriGray = Color(hex: "#89929A")
    static let mcriLightNavy = Color(hex: "#1D4865")

    /// Grey card on the navy canvas: 10.8:1 with white text, 6.0:1 with the tertiary tier.
    static let mcriSlate = Color(hex: "#303B45")
    /// Placeholder and caption grey that still clears 5:1 on a slate card.
    static let mcriMist = Color(hex: "#A9B4BD")
    static let mcriSlateText = Color(hex: "#D4DAE0")
}
