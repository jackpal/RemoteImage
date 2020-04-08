# RemoteImage

by Jack Palevich

Yet another remote image package for SwiftUI.

This one's better than most other RemoteImage implementations because:

- It takes an optional maximum size parameter, and scales down large images to fit the given maximum size.
    - by default images will be clamped to be no larger than full screen size.
- It pre-rasterizes the image off the main thread,  which greatly reduces "jank" when the image is first show.

# Example

````
import RemoteImage
import SwiftUI

struct ContentView: View {
  
    var body: some View {
      GeometryReader{proxy in
        RemoteImage(loader:ImageLoader(
          url:URL(string:"https://example.com/myimage.jpg")!,
          targetSize: proxy.size))
    }
  }
}
````
# Credits

Thanks to all the RemoteImage tutorials on the web, especially:

- [Hacking With Swift](https://www.hackingwithswift.com/example-code/uikit/how-to-load-a-remote-image-url-into-uiimageview)
- [Christian Elies](https://medium.com/better-programming/learn-master-%EF%B8%8F-remote-image-view-in-swiftui-854f8fde592c)
- [MovieSwiftUI](https://github.com/Dimillian/MovieSwiftUI)
- [SwiftUI-lab](https://swiftui-lab.com/geometryreader-to-the-rescue/) for GeometryReader insights.
- [Apple Example code](https://developer.apple.com/videos/play/wwdc2018/219/) for limiting the decoded size and pre-rasterization.

And probably other tutorials that I've accidentally omitted.

# Version History

0.0.2 - add a simple RAM cache.
0.0.1 - first version.

