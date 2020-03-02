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

# Version History

0.0.1 - first version.

