import UIKit
import Foundation

/// A bounded, user-selected, local-only static illustration shared with Shield and Widget extensions.
/// The original image is not copied; a 512px JPEG rendition is stored in the App Group container.
enum ArtworkStore {
    private static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:SharedConfig.groupID)?
            .appendingPathComponent("mascot-custom.jpg")
    }

    static func loadImage() -> UIImage? {
        guard let path=fileURL?.path else { return nil }
        return UIImage(contentsOfFile:path)
    }

    @discardableResult
    static func save(_ image:UIImage) -> Bool {
        guard let url=fileURL,
              image.size.width>0,image.size.height>0 else { return false }
        let ratio=min(1.0,512.0/max(image.size.width,image.size.height))
        let size=CGSize(width:max(1,round(image.size.width*ratio)),
                        height:max(1,round(image.size.height*ratio)))
        let rendered=UIGraphicsImageRenderer(size:size).image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin:.zero,size:size))
            image.draw(in:CGRect(origin:.zero,size:size))
        }
        guard let data=rendered.jpegData(compressionQuality:0.82),
              data.count<=1_000_000 else { return false }
        do {
            try data.write(to:url,options:.atomic)
            return true
        } catch {
            return false
        }
    }

    static func remove() {
        guard let url=fileURL else { return }
        try? FileManager.default.removeItem(at:url)
    }
}
