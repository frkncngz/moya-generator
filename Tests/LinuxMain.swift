import XCTest

import moya_generatorTests

var tests = [XCTestCaseEntry]()
tests += moya_generatorTests.allTests()
XCTMain(tests)
