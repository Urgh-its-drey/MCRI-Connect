import UIKit

/// Storage holds small images, not camera originals: a 48-megapixel HEIC costs the same to
/// fetch on a mobile plan as a 512 px JPEG but twenty times to upload.
enum MCRIImage {
    /// Re-encodes as JPEG fitted inside `maxExtent`, preserving alpha-free photos.
    /// Returns the bytes and the extension the storage path should use.
    static func downscaled(_ data: Data, maxExtent: CGFloat) -> (Data, String)? {
        guard let image = UIImage(data: data), let size = resized(image.size, maxExtent: maxExtent) else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let canvas = UIGraphicsImageRenderer(size: size, format: format)
        let scaled = canvas.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        guard let jpeg = scaled.jpegData(compressionQuality: 0.82) else { return nil }
        return (jpeg, "jpg")
    }

    static func resized(_ size: CGSize, maxExtent: CGFloat) -> CGSize? {
        guard size.width > 0, size.height > 0 else { return nil }
        let longest = max(size.width, size.height)
        guard longest > maxExtent else { return size }
        let factor = maxExtent / longest
        return CGSize(width: (size.width * factor).rounded(),
                      height: (size.height * factor).rounded())
    }
}
