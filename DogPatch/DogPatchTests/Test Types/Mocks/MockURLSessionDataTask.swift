
import Foundation


class MockURLSessionDataTask: URLSessionDataTask {

  var completionHandler: (Data?, URLResponse?, Error?) -> Void
  var url: URL
  var calledResume: Bool = false
  var calledCanel: Bool = false

  init(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void, url: URL, queue: DispatchQueue?) {

//    self.completionHandler = completionHandler

    if let queue = queue {
      self.completionHandler = { data, response, error in
        queue.async {
          completionHandler(data, response,error)
        }
      }
    } else {
      self.completionHandler = completionHandler
    }
    self.url = url
    super.init()
  }

  override func resume() {
    calledResume = true
  }

  override func cancel() {
    calledCanel = true
  }

}

