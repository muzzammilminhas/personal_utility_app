import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testRunnerBundleIsConfigured() {
    XCTAssertNotNil(Bundle.main.bundleIdentifier)
  }

}
