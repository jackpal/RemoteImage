# RemoteImage

Yet another remote image class for SwiftUI

This one's better than most other RemoteImage implementations because:

- It takes handles large images better by pre-rasterizing the image off the main thread, which reduces "jank" when the image is first show.


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
