import Combine
import Foundation
import UIKit

#if os(watchOS)
  import WatchKit
#endif

public enum ImageLoaderError: Error {
  case couldNotDecodeImage
}

public class ImageLoader: ObservableObject {
  public let url: URL
  public let targetLength: CGFloat

  private static let decodingQueue = DispatchQueue(label: "ImageLoader.decode")

  public var objectWillChange: AnyPublisher<UIImage?, Never> = Publishers.Sequence<
    [UIImage?], Never
  >(
    sequence: []).eraseToAnyPublisher()

  @Published public var image: UIImage? = nil

  private var cancellable: AnyCancellable?

  /**
   * The image is clamped in size to be no larger than the current main screen size, at
   * the full main screen scale. (Which is typically 2.0 or 3.0 for iOS devices, 1.0 for AppleTV devices, etc.)
   *
   * If the image is smaller than the main screen it is not enlarged.
   *
   * - Parameters:
   *     - url: The image URL to load asynchronously.
   *     - targetLengthPoints: The target length, in points, of the longest dimension of the image.
   *     - displayScale: The displayScale to use.
   */
  public convenience init(
    url: URL,
    targetSize: CGSize = screenSize(),
    displayScale: CGFloat = displayScale()
  ) {
    let lengthPoints = max(targetSize.height, targetSize.width)
    let targetLength = lengthPoints * displayScale
    self.init(url: url, targetLengthPixels: targetLength)
  }

  /**
   * Creates an imageloader that loads images that are clamped in size so than both height and width are `<=` targetLengthPoints * displayScale
   *
   * If the image is smaller than the clamped size it is not enlarged.
   *
   * - Parameters:
   *     - url: The image URL to load asynchronously.
   *     - targetLengthPoints: The target length, in points, of the longest dimension of the image.
   *     - displayScale: The displayScale to use.
   */
  public convenience init(
    url: URL, targetLengthPoints: CGFloat, displayScale: CGFloat = displayScale()
  ) {
    self.init(url: url, targetLengthPixels: targetLengthPoints * displayScale)
  }

  /**
   * Creates an imageloader that loads images that are clamped in size so than both height and width are `<=` targetLengthPixels.
   *
   * If the image is smaller than the clamped size it is not enlarged.
   *
   * - Parameters:
   *     - url: The image URL to load asynchronously.
   *     - targetLengthPixels: The target length, in pixels, of the longest dimension of the image.
   */
  public init(url: URL, targetLengthPixels: CGFloat) {
    self.url = url
    self.targetLength = targetLengthPixels

    self.objectWillChange = $image.handleEvents(
      receiveSubscription: { [weak self] sub in
        self?.load()
      },
      receiveCancel: { [weak self] in
        self?.cancellable?.cancel()
      }).eraseToAnyPublisher()
  }

  private func load() {
    if image == nil {
      ImageLoader.decodingQueue.async {
        self.cancellable = self.fetchImage(url: self.url)
          .receive(on: DispatchQueue.main)
          .sink(
            receiveCompletion: {
              completion in
              if case .failure(_) = completion {
                print(".sink() failed ", String(describing: completion))
              }
            },
            receiveValue: { uiImage in
              self.image = uiImage
            })
      }
    }
  }

  deinit {
    cancellable?.cancel()
  }

  private func fetchImage(url: URL) -> AnyPublisher<UIImage, Error> {
    URLSession.shared.dataTaskPublisher(for: URLRequest(url: url))
      .retry(3)
      .tryMap { (data, response) -> Data in
        return data
      }
      .receive(on: ImageLoader.decodingQueue)
      .tryMap { (data) -> UIImage in
        let uiImage = self.adaptToTargetSize(data: data)
        if uiImage != nil {
          return uiImage!
        }
        throw ImageLoaderError.couldNotDecodeImage
      }.eraseToAnyPublisher()
  }

  private func adaptToTargetSize(data: Data) -> UIImage? {
    #if os(iOS) || os(tvOS)
      // Always downsample, even if it doesn't change the size, because a side-effect
      // of downsampling is that the image is rasterized, which means it will not have
      // to be rasterized the first time it is drawn. Rasterization can cause jank if
      // done on the UI thread.
      return UIImage(data: data, targetLength: self.targetLength)
    #else
      return UIImage(data: data)
    #endif
  }
}

/// Returns the main display's current native scale. Typically 1.0, 2.0. or 3.0.
public func displayScale() -> CGFloat {
  #if os(watchOS)
    return WKInterfaceDevice.current().screenScale
  #else
    return UIScreen.main.scale
  #endif
}

/// Returns the main display's current size.
public func screenSize() -> CGSize {
  #if os(watchOS)
    return WKInterfaceDevice.current().screenBounds.size
  #else
    return UIScreen.main.bounds.size
  #endif
}

#if os(iOS) || os(tvOS)

  // Adapted from https://developer.apple.com/videos/play/wwdc2018/219/
  extension UIImage {
    public convenience init?(data: Data, targetLength: CGFloat) {
      if data.isGIF {
        self.init(firstFrameFromGIFData: data)
      } else {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions)!

        let maxDimensionInPixels = targetLength

        let downsampledOptions = [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceShouldCacheImmediately: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels,
        ] as CFDictionary
        if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
          imageSource, 0, downsampledOptions)
        {
          self.init(cgImage: downsampledImage)
        } else {
          // TODO: report an error
          return nil
        }
      }
    }
  }

#endif  // os(iOS) || os(tvOS)
