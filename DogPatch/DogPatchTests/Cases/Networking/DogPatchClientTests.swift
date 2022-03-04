

@testable import DogPatch
import XCTest

class DogPatchClientTests: XCTestCase {

  var sut: DogPatchClient!
  var baseURL: URL!
  var mockSession: MockURLSession!
  var getDogsURL: URL {
    return URL(string: "dogs", relativeTo: baseURL)!
  }

  override func setUp() {
    super.setUp()
    baseURL = URL(string: "https://example.com/api/v1/")!
    mockSession = MockURLSession()
    sut = DogPatchClient(baseURL: baseURL, session: mockSession, responseQueue: nil)
  }

  override func tearDown() {
    baseURL = nil
    mockSession = nil
    sut = nil
    super.tearDown()
  }

  func whenGetDogs(data: Data? = nil, statusCode: Int = 200, error: Error? = nil) ->
  (calledCompletion: Bool, dogs: [Dog]?, error: Error?) {

    let response = HTTPURLResponse(url: getDogsURL,
                                   statusCode: statusCode,
                                   httpVersion: nil,
                                   headerFields: nil)

    var calledCompletion = false
    var receivedDogs: [Dog]? = nil
    var receivedError: Error? = nil

    let mockTask = sut.getDogs { dogs, error in
      calledCompletion = true
      receivedDogs = dogs
      receivedError = error as NSError?
    } as! MockURLSessionDataTask

    mockTask.completionHandler(data, response, error)
    return (calledCompletion, receivedDogs, receivedError)
  }

  func verifyGetDogsDispatchedToMain(data: Data? = nil,
                                     statusCode: Int = 200,
                                     error: Error? = nil,
                                     line: UInt = #line) {

    mockSession.givenDispatchQueue()
    sut = DogPatchClient(baseURL: getDogsURL,
                         session: mockSession,
                         responseQueue: .main)

    let expectation = self.expectation(description: "Completion wasn't called")

    // when
    var thread: Thread!
    let mockTask = sut.getDogs { dogs, error in
      thread = Thread.current
      expectation.fulfill()
    } as! MockURLSessionDataTask

    let response = HTTPURLResponse(url: getDogsURL,
                                   statusCode: statusCode,
                                   httpVersion: nil,
                                   headerFields: nil)

    mockTask.completionHandler(data, response, error)

    // then
    waitForExpectations(timeout: 0.2) { error in
      XCTAssertTrue(thread.isMainThread, line: line)
    }
  }

  func test_init_sets_baseURL() {
    // given
//    let baseURL = URL(string: "https://example.com/api/v1/")!
//    let session = URLSession.shared
//
//    // when
//    sut = DogPatchClient(baseURL: baseURL, session: session)

    // then
    XCTAssertEqual(sut.baseURL, baseURL)
  }

  func test_init_sets_session() {
    // given
//    let baseURL = URL(string: "https://example.com/api/v1/")!
//    let session = URLSession.shared
//
//    // when
//    sut = DogPatchClient(baseURL: baseURL, session: session)

    // then
    XCTAssertEqual(sut.session, mockSession)
  }

  func test_getDogs_callExpectedURL() {
    // given
//    let getDogsURL = URL(string: "dogs", relativeTo: baseURL)

    // when
    let mockTask = sut.getDogs() {_, _ in } as! MockURLSessionDataTask

    // then
    XCTAssertEqual(mockTask.url, getDogsURL)
  }

  func test_getDogs_callsResumeOnTask() {
    // when
    let mockTask = sut.getDogs { _, _ in } as! MockURLSessionDataTask

    // then
    XCTAssertTrue(mockTask.calledResume)
  }

  func test_getDogs_givenResponseStatusCode500_callsCompletion() {
    /*
    // given
//    let getDogsURL = URL(string: "dogs", relativeTo: baseURL)!
    let response = HTTPURLResponse(url: getDogsURL,
                                   statusCode: 500,
                                   httpVersion: nil,
                                   headerFields: nil)

    // when
    var calledCompletion = false
    var receivedDogs: [Dog]? = nil
    var receivedError: Error? = nil

    let mockTask = sut.getDogs { dogs, error in
      calledCompletion = true
      receivedDogs = dogs
      receivedError = error
    } as? MockURLSessionDataTask

    mockTask?.completionHandler(nil, response, nil)

    // then
    XCTAssertTrue(calledCompletion)
    XCTAssertNil(receivedDogs)
    XCTAssertNil(receivedError)
    */

    // when
    let result = whenGetDogs(statusCode: 500)

    // then
    XCTAssertTrue(result.calledCompletion)
    XCTAssertNil(result.dogs)
    XCTAssertNil(result.error)
  }

  func test_getDogs_givenError_callsCompletionWithError() throws {
    /*
    // given
    let response = HTTPURLResponse(url: getDogsURL,
                                   statusCode: 200,
                                   httpVersion: nil,
                                   headerFields: nil)

    let expectedError = NSError(domain: "com.DogPatchTests",
                                code: 42,
                                userInfo: nil)

    // when
    var calledCompletion = false
    var receivedDogs: [Dog]? = nil
    var receivedError: Error? = nil

    let mockTask = sut.getDogs { dogs, error in
      calledCompletion = true
      receivedDogs = dogs
      receivedError = error as NSError?
    } as! MockURLSessionDataTask

    mockTask.completionHandler(nil, response, expectedError)

    // then
    XCTAssertTrue(calledCompletion)
    XCTAssertNil(receivedDogs)

    let actualError = try XCTUnwrap(receivedError as NSError?)
    XCTAssertEqual(actualError, expectedError)

    */

    // given
    let expectedError = NSError(domain: "com.DogPatchTests",
                                code: 42,
                                userInfo: nil)

    // when
    let result = whenGetDogs(error: expectedError)

    // then
    XCTAssertTrue(result.calledCompletion)
    XCTAssertNil(result.dogs)

    let actualError = try XCTUnwrap(result.error as NSError?)
    XCTAssertEqual(actualError, expectedError)
  }

  func test_getDogs_givenValidJSON_callsCompletionWithDogs() throws {

    // given
    let data = try Data.fromJSON(fileName: "GET_Dogs_Response")

    let decoder = JSONDecoder()
    let dogs = try decoder.decode([Dog].self, from: data)

    // when
    let result = whenGetDogs(data: data)

    // then
    XCTAssertTrue(result.calledCompletion)
    XCTAssertEqual(result.dogs, dogs)
    XCTAssertNil(result.error)
  }

  func test_getDogs_givenInvalidJSON_callsCompletionWithError() throws {
    // given
    let data = try Data.fromJSON(fileName: "GET_Dogs_MissingValuesResponse")

    var expectedError: NSError!
    let decoder = JSONDecoder()
    do {
      _ = try decoder.decode([Dog].self, from: data)
    } catch {
      expectedError = error as NSError
    }

    // when
    let result = whenGetDogs(data: data)

    // then
    XCTAssertTrue(result.calledCompletion)
    XCTAssertNil(result.dogs)

    let actualError = try XCTUnwrap(result.error as NSError?)
    XCTAssertEqual(actualError.domain, expectedError.domain)
    XCTAssertEqual(actualError.code, expectedError.code)

  }

  func test_init_sets_responseQueue () {
    // given
    let responseQueue = DispatchQueue.main

    // when
    sut = DogPatchClient(baseURL: baseURL,
                         session: mockSession,
                         responseQueue: responseQueue)

    // then
    XCTAssertEqual(sut.responseQueue, responseQueue)
  }


  func test_getDogs_givenHTTPStatusError_dispatchesToResponseQueue() {
    /*
    // given
    mockSession.givenDispatchQueue()
    sut = DogPatchClient(baseURL: baseURL,
                         session: mockSession,
                         responseQueue: .main)

    let expectation = self.expectation(description: "Completion wasn't called")

    // when
    var thread: Thread!
    let mockTask = sut.getDogs { dogs, error in
      thread = Thread.current
      expectation.fulfill()
    } as? MockURLSessionDataTask

    let response = HTTPURLResponse(url: getDogsURL,
                                   statusCode: 500,
                                   httpVersion: nil,
                                   headerFields: nil)

    mockTask?.completionHandler(nil, response, nil)




    // then
    waitForExpectations(timeout: 0.2) { _ in
      XCTAssertTrue(thread.isMainThread)
    }
    */

    verifyGetDogsDispatchedToMain(statusCode: 500)
  }

  func test_getDogs_givenError_DispatchedToResponseQueue() {
    /*
    // given
    mockSession.givenDispatchQueue()
    sut = DogPatchClient(baseURL: baseURL,
                         session: mockSession,
                         responseQueue: .main)

    let expectation = self.expectation(description: "Completion wasn't called")

    // when
    var thread: Thread!
    let mockTask = sut.getDogs { dogs, error in
      thread = Thread.current
      expectation.fulfill()
    } as? MockURLSessionDataTask

    let response = HTTPURLResponse(url: getDogsURL,
                                   statusCode: 200,
                                   httpVersion: nil,
                                   headerFields: nil)

    let error = NSError(domain: "com.DogPatchTests",
                        code: 42,
                        userInfo: nil)

    mockTask?.completionHandler(nil, response, error)

    // then
    waitForExpectations(timeout: 0.2) { error in
      XCTAssertTrue(thread.isMainThread)
    }
    */

    // when
    let error = NSError(domain: "com.DogPatchTests",
                        code: 42,
                        userInfo: nil)

    // then
    verifyGetDogsDispatchedToMain(error: error)
  }

  func test_getDogs_givenGoodResponse_dispatchesToResponseQueue() throws {
    // given
    let data = try Data.fromJSON(fileName: "GET_Dogs_Response")

    // then
    verifyGetDogsDispatchedToMain(data: data)
  }

  func test_getDogs_givenInvalidResponse_dispatchesToResponseQueue() throws {
    // given
    let data = try Data.fromJSON(fileName: "GET_Dogs_MissingValuesResponse")

    // then
    verifyGetDogsDispatchedToMain(data: data)
  }

  func test_conformsTo_DogPathService() {
    XCTAssertTrue((sut as AnyObject) is DogPatchService)
  }

  func test_dogPatchService_declaresGetDogs() {
    // given
    let service = sut as DogPatchService

    // then
    _ = service.getDogs() {_, _ in }
  }

  func test_shared_setsBaseURL() {
    // given
    let baseURL = URL(string: "https://dogpatchserver.herokuapp.com/api/v1/")

    // then
    XCTAssertEqual(DogPatchClient.shared.baseURL, baseURL)
  }

  func test_shared_setSession() {
    // given
    let session = URLSession.shared

    // then
    XCTAssertEqual(DogPatchClient.shared.session, session)
  }

  func test_shared_setResponseQueue() {
    // given
    let responseQueue = DispatchQueue.main

    // then
    XCTAssertEqual(DogPatchClient.shared.responseQueue, responseQueue)
  }
}

