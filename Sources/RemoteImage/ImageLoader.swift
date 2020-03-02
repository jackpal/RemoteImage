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

  public var objectWillChange: AnyPublisher<UIImage?, Never> = Publishers.Sequence<[UIImage?], Never>(
    sequence: []).eraseToAnyPublisher()

  @Published public var image: UIImage? = nil

  private var cancellable: AnyCancellable?

  public convenience init(url: URL, displayScale: CGFloat) {
    self.init(url: url, targetSize: screenSize(), displayScale: displayScale)
  }

  public convenience init(url: URL, targetSize: CGSize, displayScale: CGFloat) {
    let lengthPoints = max(targetSize.height, targetSize.width)
    let targetLength = lengthPoints * displayScale
    self.init(url: url, targetLengthPixels: targetLength)
  }

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
    return downsample(imageData: data, to: self.targetLength)
    #else
    return UIImage(data:data)
    #endif
  }
}

func screenSize() -> CGSize {
  #if os(watchOS)
    return WKInterfaceDevice.current().screenBounds.size
  #else
    return UIScreen.main.bounds.size
  #endif
}

#if os(iOS) || os(tvOS)

// Adapted from https://developer.apple.com/videos/play/wwdc2018/219/
func downsample(imageData: Data, to targetLength: CGFloat) -> UIImage? {
  if UIImage.isGIF(data: imageData) {
    return UIImage.firstImageFromGIF(data: imageData)
  }
  let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
  let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions)!

  let maxDimensionInPixels = targetLength

  let downsampledOptions = [
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceShouldCacheImmediately: true,
    kCGImageSourceCreateThumbnailWithTransform: true,
    kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels,
  ] as CFDictionary
  if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledOptions)
  {
    return UIImage(cgImage: downsampledImage)
  } else {
    // TODO: report an error
    return nil
  }
}

#endif // os(iOS) || os(tvOS)

