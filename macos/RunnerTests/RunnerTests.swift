import Cocoa
import FlutterMacOS
import XCTest

class RunnerTests: XCTestCase {

  func testRunnerBundleIsConfigured() {
    XCTAssertNotNil(Bundle.main.bundleIdentifier)
  }

}
