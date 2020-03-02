import Foundation
import UIKit

#if os(iOS) || os(tvOS)

  extension UIImage {
    convenience init?(firstFrameFromGIFData data: Data) {
      guard let source = CGImageSourceCreateWithData(data as CFData, nil)
      else {
        return nil
      }
      guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        return nil
      }
      self.init(cgImage: cgImage)
    }
  }

#endif  // os(iOS) || os(tvOS)

extension Data {
  var isGIF: Bool {
    return self.starts(with: Data.GIF89aHeader)
  }

  static private let GIF89aHeader = "GIF89a".utf8
}
