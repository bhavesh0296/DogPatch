
@testable import DogPatch
import UIKit
import XCTest

class ImageClientTests: XCTestCase {

  var mockSession : MockURLSession!
  var sut: ImageClient!
  var service: ImageService {
    sut as ImageService
  }
  var url: URL!
  var receivedDataTask: MockURLSessionDataTask!
  var receivedError: Error!
  var receivedImage: UIImage!
  var expectedImage: UIImage!
  var expectedError: NSError!
  var imageView: UIImageView!


  override func setUp() {
    super.setUp()
    url = URL(string: "https://example.com/image")!
    imageView = UIImageView()
    mockSession = MockURLSession()
    sut = ImageClient(responseQueue: nil,
                      session: mockSession)
  }

  override func tearDown() {
    mockSession = nil
    sut = nil
    url = nil
    receivedDataTask = nil
    receivedError = nil
    receivedImage = nil
    expectedImage = nil
    expectedError = nil
    imageView = nil
    super.tearDown()
  }

  func givenExpectedImage() {
    expectedImage = UIImage(named: "happy_dog")!
  }

  func givenExpectedError() {
    expectedError = NSError(domain: "com.example",
                            code: 42,
                            userInfo: nil)
  }

  func whenDownloadImage(image: UIImage? = nil, error: Error? = nil) {
    
    receivedDataTask = sut.downloadImage(fromURL: url, completion: { image, error in
      self.receivedImage = image
      self.receivedError = error
    }) as? MockURLSessionDataTask

    if let receivedDataTask = receivedDataTask {
      if let image = image {
        receivedDataTask.completionHandler(image.pngData(), nil, nil)
      } else if let error = error {
        receivedDataTask.completionHandler(nil, nil, error)
      }
    }
  }

  func whenSetImage() {
    givenExpectedImage()
    sut.setImage(on: imageView,
                 fromURL: url,
                 withPlaceholder: nil)
    receivedDataTask = sut.cachedTaskForImageView[imageView] as? MockURLSessionDataTask
    receivedDataTask.completionHandler(expectedImage.pngData(), nil, nil)

  }

  func verifyDownloadImageDispatched(image: UIImage? = nil,
                                     error: Error? = nil,
                                     line: UInt = #line) {

    mockSession.givenDispatchQueue()
    sut = ImageClient(responseQueue: .main,
                      session: mockSession)
    var receivedThread: Thread!
    let expectation = self.expectation(description: "completion wasn't called")

    let dataTask = sut.downloadImage(fromURL: url) { _, _ in
      receivedThread = Thread.current
      expectation.fulfill()
    } as! MockURLSessionDataTask

    dataTask.completionHandler(image?.pngData(), nil, error)

    waitForExpectations(timeout: 1.0) { error in
      //
    }
    XCTAssertTrue(receivedThread.isMainThread)
  }

  // MARK: - static properties tests
  func test_shared_setResponseQueue() {
    XCTAssertEqual(ImageClient.shared.responseQueue, .main )
  }

  func test_shared_setsSession() {
    XCTAssertEqual(ImageClient.shared.session, .shared)
  }

  // MARK: - object lifecycle tests
  func test_init_setCachedImageURL() {
    XCTAssertEqual(sut.cachedImageURL, [:])
  }

  func test_init_setCachedTaskForImageView() {
    XCTAssertEqual(sut.cachedTaskForImageView, [:])
  }

  func test_init_setResponseQueue() {
    XCTAssertEqual(sut.responseQueue, nil)
  }

  func test_init_setsSessoin() {
    XCTAssertEqual(sut.session, mockSession)
  }

  func test_confomsTo_ImageService() {
    XCTAssertTrue((sut as AnyObject) is ImageService)
  }

  func test_imageService_declaresDownloadImage() {
    // given
//    let url = URL(string: "https://example.com/image")!
//    let service = sut as ImageService

    // then
    _ = service.downloadImage(fromURL: url) {_, _ in }
  }

  func test_imageService_declaresSetImageOnImageView() {
    // given
//    let service = sut as ImageService
//    let imageView = UIImageView()
//    let url = URL(string: "https://example.com/image")!
    let placeholder = UIImage(named: "image_placeholder")!

    // then
    service.setImage(on: imageView,
                     fromURL: url,
                     withPlaceholder: placeholder)

  }

  func test_downloadImage_createsExpectedDataTask() {
    // when
//    let dataTask = sut.downloadImage(fromURL: url) { _, _ in
//
//    } as? MockURLSessionDataTask
    whenDownloadImage()

    // then
//    XCTAssertEqual(dataTask?.url, url)
    XCTAssertEqual(receivedDataTask.url, url)
  }

  func test_downloadImage_callsResumeOnDataTask() {
    // when
//    let dataTask = sut.downloadImage(fromURL: url) { _, _ in
//
//    } as? MockURLSessionDataTask
    whenDownloadImage()

    // then
//    XCTAssertTrue(dataTask!.calledResume)
    XCTAssertTrue(receivedDataTask.calledResume)
  }

  func test_downloadImage_givenImage_callsCompletionWithImage() {
    // given
//    let exptectedImage = UIImage(named: "happy_dog")!
    givenExpectedImage()

    // when
    whenDownloadImage(image: expectedImage)

    // then
    XCTAssertEqual(expectedImage.pngData(), receivedImage.pngData())
  }

  func test_downloadImage_givenError_callsCompletionWithError() {
    // given
//    let expectedError = NSError(domain: "com.example",
//                                code: 42,
//                                userInfo: nil)
    givenExpectedError()

    // when
    whenDownloadImage(error: expectedError)

    // then
    XCTAssertEqual(expectedError, receivedError as NSError)
  }

  func test_downloadImage_givenImage_dispatchesToResponseQueue() {
    // given
    /*
    mockSession.givenDispatchQueue()
    sut = ImageClient(responseQueue: .main,
                      session: mockSession)
//    let expectedImage = UIImage(named: "happy_dog")
    givenExpectedImage()
    var receivedThread: Thread!
    let expectation = self.expectation(description: "Completion wasn't called")

    // when
    let dataTask = sut.downloadImage(fromURL: url) { image, error in
      receivedThread = Thread.current
      expectation.fulfill()
    } as! MockURLSessionDataTask

    dataTask.completionHandler(expectedImage?.pngData(), nil, nil)

    // then
    waitForExpectations(timeout: 1.0)
    XCTAssertTrue(receivedThread.isMainThread)
    */

    // given
    givenExpectedImage()


    // then
    verifyDownloadImageDispatched(image: expectedImage)
  }

  func test_downloadImage_givenError_dispatchedToResponseQueue() {
    // given
    /*

    mockSession.givenDispatchQueue()
    sut = ImageClient(responseQueue: .main,
                      session: mockSession)
    let expectedError = NSError(domain: "com.example",
                                code: 42,
                                userInfo: nil)
    var receivedThread: Thread!
    let expectation = self.expectation(description: "Completion wasn't called")

    // when
    let dataTask = sut.downloadImage(fromURL: url) { _, _ in
      receivedThread = Thread.current
      expectation.fulfill()
    } as! MockURLSessionDataTask

    dataTask.completionHandler(nil, nil, expectedError)

    // then
    waitForExpectations(timeout: 1.0)
    XCTAssertTrue(receivedThread.isMainThread)

    */

    // given
    givenExpectedError()

    // then
    verifyDownloadImageDispatched(image: nil, error: expectedError)


  }

  func test_downloadImage_givenImage_cachesImage() {
    // given
    givenExpectedImage()

    // when
    whenDownloadImage(image: expectedImage)

    // then
    XCTAssertEqual(sut.cachedImageURL[url]?.pngData(), expectedImage.pngData())
  }

  func test_donwloadImage_givenCachedImage_returnsNilDataTask() {
    // given
    givenExpectedImage()

    // when
    whenDownloadImage(image: expectedImage)
    whenDownloadImage(image: expectedImage)

    // then
    XCTAssertNil(receivedDataTask)
  }

  func test_downloadImage_givenCachedImage_callsCompletionWithImage() {
    // given
    givenExpectedImage()

    // when
    whenDownloadImage(image: expectedImage)
    receivedImage = nil

    whenDownloadImage(image: expectedImage)

    // then
    XCTAssertEqual(receivedImage.pngData(), expectedImage.pngData())
  }

  func test_setImageOnImageView_cancelsExistingDataTask() {
    // given
    let dataTask = MockURLSessionDataTask(completionHandler: { _, _, _ in

    }, url: url, queue: nil)
//    let imageView = UIImageView()
    sut.cachedTaskForImageView[imageView] = dataTask

    // when
    sut.setImage(on: imageView,
                 fromURL: url,
                 withPlaceholder: nil)

    // then
    XCTAssertTrue(dataTask.calledCanel)
  }


  func test_setImageOnImageView_setsPlaceHolderOnImageView() {
    // given
    givenExpectedImage()
//    let imageView = UIImageView()

    // when
    sut.setImage(on: imageView,
                 fromURL: url,
                 withPlaceholder: expectedImage)

    // then
    XCTAssertEqual(imageView.image?.pngData(), expectedImage.pngData())
  }

  func test_setsImageOnImageView_cachesDownloadTask() {
    // when
    sut.setImage(on: imageView,
                 fromURL: url,
                 withPlaceholder: nil)

    receivedDataTask = sut.cachedTaskForImageView[imageView] as? MockURLSessionDataTask

    // then
    XCTAssertEqual(receivedDataTask?.url, url)
  }

  func test_setsImageOnImageView_onCompletionRemovesDataTask() {
    // given
    givenExpectedImage()

    // when
//    sut.setImage(on: imageView,
//                 fromURL: url,
//                 withPlaceholder: nil)
//    receivedDataTask = sut.cachedTaskForImageView[imageView] as? MockURLSessionDataTask
//    receivedDataTask.completionHandler(expectedImage.pngData(), nil, nil)
    whenSetImage()

    // then
    XCTAssertNil(sut.cachedTaskForImageView[imageView])
  }

  func test_setImageOnImageView_onCompletionSetsImage() {
    // given
    givenExpectedImage()

    // when
//    sut.setImage(on: imageView,
//                 fromURL: url,
//                 withPlaceholder: nil)
//    receivedDataTask = sut.cachedTaskForImageView[imageView] as? MockURLSessionDataTask
//    receivedDataTask.completionHandler(expectedImage.pngData(), nil, nil)
    whenSetImage()

    // then
    XCTAssertEqual(imageView.image?.pngData(), expectedImage.pngData())
  }

  func test_setImageOnImageView_givenError_doesnSetImage() {
    // given
    givenExpectedImage()
    givenExpectedError()

    // when
    sut.setImage(on: imageView,
                 fromURL: url,
                 withPlaceholder: expectedImage)
    receivedDataTask = sut.cachedTaskForImageView[imageView] as? MockURLSessionDataTask
    receivedDataTask.completionHandler(nil, nil, expectedError)

    // then
    XCTAssertEqual(imageView.image?.pngData(), expectedImage.pngData())
  }
}
