import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(moya_generatorTests.allTests),
    ]
}
#endif
