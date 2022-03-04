
import Foundation

class MockURLSession: URLSession {

  var queue: DispatchQueue? = nil

  override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {

    return MockURLSessionDataTask(completionHandler: completionHandler,
                                  url: url,
                                  queue: queue)
  }

  func givenDispatchQueue() {
    queue = DispatchQueue(label: "com.DogPatchTests.MockSession")
  }
}
