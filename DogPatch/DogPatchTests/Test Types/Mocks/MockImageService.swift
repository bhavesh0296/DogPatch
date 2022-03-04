
@testable import DogPatch
import UIKit

class MockImageService: ImageService {

  func downloadImage(fromURL url: URL, completion: @escaping (UIImage?, Error?) -> Void) -> URLSessionDataTask? {

    return nil
  }

  var setImageCallCount = 0
  var receivedImageView: UIImageView!
  var receivedURL: URL!
  var receivedPlaceholder: UIImage!

  func setImage(on imageView: UIImageView, fromURL url: URL, withPlaceholder placeholder: UIImage?) {
    setImageCallCount += 1
    receivedImageView = imageView
    receivedURL = url
    receivedPlaceholder = placeholder
  }
}
