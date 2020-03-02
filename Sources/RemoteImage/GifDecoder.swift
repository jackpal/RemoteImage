#if os(iOS) || os(tvOS)
import Foundation
import UIKit

extension UIImage {
  static func firstImageFromGIF(data: Data) -> UIImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil)
    else {
      return nil
    }
    guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      return nil
    }
    return UIImage(cgImage: cgImage)
  }

  static private let GIF89aHeader = "GIF89a".utf8

  static func isGIF(data: Data) -> Bool {
    return data.starts(with: GIF89aHeader)
  }
}

#endif // os(iOS) || os(tvOS)
