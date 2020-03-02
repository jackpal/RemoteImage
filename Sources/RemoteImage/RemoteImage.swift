import SwiftUI

public struct RemoteImage: View {
  @ObservedObject var loader: ImageLoader
  @State var isImageLoaded = false

  init(loader: ImageLoader) {
    self.loader = loader
  }

  public var body: some View {
    // Fetch once, because image can be evicted from cache
    // between consecutive calls to loader.
    let image = loader.image
    return ZStack {
      if image != nil {
        // Use a state variable and an animation instead of
        // a transition due to what appears to be a SwiftUI bug:
        // Fade-in transitions sometimes hang.
        // The repro case is to scroll a
        // thread with many large image posts. A few of the posts
        // will be black or dim. It seems that the image
        // is loaded, but the transition animation to fade-in
        // the image doesn't complete.
        Image(uiImage: image!)
          .renderingMode(.original)
          .resizable()
          .opacity(self.isImageLoaded ? 1 : 0)
          .animation(.easeInOut(duration: 0.2))
          .onAppear {
            self.isImageLoaded = true
          }
      } else {
        Color(.gray)
          .opacity(0.2)
      }
    }
  }
}
