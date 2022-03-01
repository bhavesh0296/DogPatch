
@testable import DogPatch
import Foundation

class MockDogPatchService: DogPatchService {

  var getDogsCallCount = 0
  var getDogsDataTask = URLSessionDataTask()
  var getDogsCompletion: (([Dog]?, Error?) -> Void)!

  func getDogs(completion: @escaping ([Dog]?, Error?) -> Void) -> URLSessionDataTask {
    getDogsCallCount += 1
    getDogsCompletion = completion
    return getDogsDataTask
  }
}
