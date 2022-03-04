
import UIKit

protocol ImageService {
  func downloadImage(fromURL url: URL,
                     completion: @escaping (UIImage?, Error?) -> Void) -> URLSessionDataTask?

  func setImage(on imageView: UIImageView,
                fromURL url: URL,
                withPlaceholder placeholder: UIImage?)
}

class ImageClient {

  static let shared = ImageClient(responseQueue: .main,
                                  session: .shared)

  var cachedImageURL: [URL: UIImage]
  var cachedTaskForImageView: [UIImageView: URLSessionDataTask]

  let responseQueue: DispatchQueue?
  let session: URLSession

  init(responseQueue: DispatchQueue?, session: URLSession) {
    self.cachedImageURL = [:]
    self.cachedTaskForImageView = [:]

    self.responseQueue = responseQueue
    self.session = session
  }



}

// MARK: - ImageService
extension ImageClient: ImageService {


  func downloadImage(fromURL url: URL, completion: @escaping (UIImage?, Error?) -> Void) -> URLSessionDataTask? {

    if let image = cachedImageURL[url] {
      completion(image, nil)
      return nil
    }

    let dataTask = session.dataTask(with: url) { [weak self] data, response, error in
      //
      guard let self = self else { return }
      if let data = data,
         let image = UIImage(data: data) {
//        if let responseQueue = self.responseQueue {
//          responseQueue.async {
//            completion(image, nil)
//          }
//        } else {
//          completion(image, nil)
//        }
//        completion(image, nil)

        self.cachedImageURL[url] = image

        self.dispatch(image: image,
                      completion: completion)
      } else {

//        if let responseQueue = self.responseQueue {
//          responseQueue.async {
//            completion(nil, error)
//          }
//        } else {
//          completion(nil, error)
//        }

        self.dispatch(error: error,
                      completion: completion)
      }
    }

    dataTask.resume()

    return dataTask
  }

  func setImage(on imageView: UIImageView, fromURL url: URL, withPlaceholder placeholder: UIImage?) {
    cachedTaskForImageView[imageView]?.cancel()
    imageView.image = placeholder
    cachedTaskForImageView[imageView] = downloadImage(fromURL: url,
                                                      completion: { [weak self] image, error in
      guard let self = self else { return }
      self.cachedTaskForImageView[imageView] = nil
      guard let image = image else {
        print("Set image failed with error:" + String(describing: error))
        return
      }
      imageView.image = image
//      imageView.image = image
    })
  }


  private func dispatch(image: UIImage? = nil,
                                     error: Error? = nil,
                                     completion: @escaping (UIImage?, Error?) -> Void) {

     guard let responseQueue = self.responseQueue else {
       completion(image, error)
       return
     }
     responseQueue.async {
       completion(image, error)
     }
   }
}
