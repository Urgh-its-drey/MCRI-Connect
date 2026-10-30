import SwiftUI
import PhotosUI

/// The photo chooser used on all three sides — a student's portrait, a company logo, a
/// manager's own photo. `PhotosPicker` reads only the image the user taps, so the app needs
/// no photo-library usage string and never sees the rest of the library.
struct MCRIAvatarPicker: View {
    var title: String
    var initials: String
    var bucket: StorageBucket
    var currentPath: String?
    var maxExtent: CGFloat = 512
    var isCircle: Bool = false
    var onPick: (Data, String) -> Void

    @State private var item: PhotosPickerItem?
    @State private var isWorking = false

    var body: some View {
        HStack(alignment: .center, spacing: MCRITheme.Spacing.s4) {
            MCRILogoTile(initials: initials, size: 64, imageURL: url, isCircle: isCircle)

            VStack(alignment: .leading, spacing: 5) {
                Text(title).mcriLabelStyle()

                PhotosPicker(selection: $item, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: isWorking ? "hourglass" : "photo.on.rectangle.angled")
                            .font(.system(size: 12, weight: .semibold))
                        Text(isWorking ? "Uploading…" : "Choose photo")
                            .font(.mcriCaption.weight(.semibold))
                    }
                    .foregroundStyle(MCRITheme.textOnAccent)
                    .padding(.horizontal, MCRITheme.Spacing.s4)
                    .frame(height: 38)
                    .background(isWorking ? MCRITheme.placeholder : MCRITheme.primaryAction,
                                in: Capsule())
                }
                .disabled(isWorking)

                Text("Square reads best. Stored at up to \(Int(maxExtent)) px.")
                    .font(.mcriCaption2)
                    .foregroundStyle(MCRITheme.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .onChange(of: item) { _, picked in
            guard let picked else { return }
            isWorking = true
            Task {
                defer { isWorking = false }
                guard let raw = try? await picked.loadTransferable(type: Data.self),
                      let encoded = MCRIImage.downscaled(raw, maxExtent: maxExtent) else {
                    return
                }
                onPick(encoded.0, encoded.1)
                item = nil
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var url: URL? { mcriImageURL(bucket: bucket, path: currentPath) }
}
