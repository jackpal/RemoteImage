#if os(iOS) || os(tvOS)
import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RemoteImageTests.allTests),
    ]
}
#endif
#endif
