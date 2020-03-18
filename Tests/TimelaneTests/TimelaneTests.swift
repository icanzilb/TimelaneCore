import XCTest
import os
@testable import TimelaneCore

@available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
final class TimelaneTests: XCTestCase {
    func testEmitsVersion() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = false
        let sub = Timelane.Subscription(name: "Test Subscription", logger: recorder.log)
        sub.event(value: .value("1"))
        
        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }
        
        XCTAssertEqual(recorder.logged[0].version, "1")
    }
    
    func testEmitsEventValues() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true
        let sub = Timelane.Subscription(name: "Test Subscription", logger: recorder.log)
        sub.event(value: .value("1"))
        sub.event(value: .value("2"))
        sub.event(value: .value("3"))
        
        XCTAssertEqual(recorder.logged.count, 3)
        guard recorder.logged.count == 3 else {
            return
        }
        
        XCTAssertEqual(recorder.logged[0].type, "Output")
        XCTAssertEqual(recorder.logged[0].subscription, "Test Subscription")
        XCTAssertEqual(recorder.logged[0].value, "1")

        XCTAssertEqual(recorder.logged[1].type, "Output")
        XCTAssertEqual(recorder.logged[1].subscription, "Test Subscription")
        XCTAssertEqual(recorder.logged[1].value, "2")

        XCTAssertEqual(recorder.logged[2].type, "Output")
        XCTAssertEqual(recorder.logged[2].subscription, "Test Subscription")
        XCTAssertEqual(recorder.logged[2].value, "3")
    }

    func testEmitsSubscriptions() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true
        let sub1 = Timelane.Subscription(name: "Test Subscription 1", logger: recorder.log)
        sub1.begin()
        sub1.event(value: .value("1"))

        let sub2 = Timelane.Subscription(name: "Test Subscription 2", logger: recorder.log)
        sub2.begin()
        sub2.event(value: .value("2"))
        sub1.event(value: .value("3"))
        
        XCTAssertEqual(recorder.logged.count, 5)
        guard recorder.logged.count == 5 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].signpostType, "begin")
        XCTAssertEqual(recorder.logged[0].subscribe, "Test Subscription 1")

        XCTAssertEqual(recorder.logged[1].signpostType, "event")
        XCTAssertEqual(recorder.logged[1].type, "Output")
        XCTAssertEqual(recorder.logged[1].subscription, "Test Subscription 1")
        XCTAssertEqual(recorder.logged[1].value, "1")

        XCTAssertEqual(recorder.logged[2].signpostType, "begin")
        XCTAssertEqual(recorder.logged[2].subscribe, "Test Subscription 2")

        XCTAssertEqual(recorder.logged[3].signpostType, "event")
        XCTAssertEqual(recorder.logged[3].type, "Output")
        XCTAssertEqual(recorder.logged[3].subscription, "Test Subscription 2")
        XCTAssertEqual(recorder.logged[3].value, "2")

        XCTAssertEqual(recorder.logged[4].signpostType, "event")
        XCTAssertEqual(recorder.logged[4].type, "Output")
        XCTAssertEqual(recorder.logged[4].subscription, "Test Subscription 1")
        XCTAssertEqual(recorder.logged[4].value, "3")
    }

    static var allTests = [
        ("testEmitsVersion", testEmitsVersion),
        ("testEmitsEventValues", testEmitsEventValues),
        ("testEmitsSubscriptions", testEmitsSubscriptions),
    ]
}
