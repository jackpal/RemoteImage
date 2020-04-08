import UIKit

struct ImageCache {
  static var shared = ImageCache()
  private let cache = NSCache<NSString, UIImage>()
  
  subscript(_ key: String) -> UIImage? {
    get { cache.object(forKey: key as NSString) }
    set {
      newValue == nil ? cache.removeObject(forKey: key as NSString)
        : cache.setObject(newValue!, forKey: key as NSString)
    }
  }
}

