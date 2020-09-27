import XCTest
import os
import TimelaneCoreTestUtils
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
        
        XCTAssertEqual(recorder.logged[0].version, "2")
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
        
        XCTAssertEqual(recorder.logged[0].outputTldr, "Output, Test Subscription, 1")
        XCTAssertEqual(recorder.logged[1].outputTldr, "Output, Test Subscription, 2")
        XCTAssertEqual(recorder.logged[2].outputTldr, "Output, Test Subscription, 3")
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
        XCTAssertEqual(recorder.logged[1].outputTldr, "Output, Test Subscription 1, 1")

        XCTAssertEqual(recorder.logged[2].signpostType, "begin")
        XCTAssertEqual(recorder.logged[2].subscribe, "Test Subscription 2")

        XCTAssertEqual(recorder.logged[3].signpostType, "event")
        XCTAssertEqual(recorder.logged[3].outputTldr, "Output, Test Subscription 2, 2")

        XCTAssertEqual(recorder.logged[4].signpostType, "event")
        XCTAssertEqual(recorder.logged[4].outputTldr, "Output, Test Subscription 1, 3")
    }

    func testCompletions() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true
        let sub1 = Timelane.Subscription(name: "Test Subscription 1", logger: recorder.log)
        sub1.end(state: .cancelled)

        let sub2 = Timelane.Subscription(name: "Test Subscription 2", logger: recorder.log)
        sub2.end(state: .completed)

        let sub3 = Timelane.Subscription(name: "Test Subscription 3", logger: recorder.log)
        sub3.end(state: .error("Test Error"))

        XCTAssertEqual(recorder.logged.count, 3)
        guard recorder.logged.count == 3 else {
            return
        }
        
        // This needs a rewrite when this one is addressed
        // TODO: https://github.com/icanzilb/TimelaneCore/issues/16

        XCTAssertEqual(recorder.logged[0].signpostType, "end")
        XCTAssertTrue(recorder.logged[0].log.hasPrefix("completion:1"))
        
        XCTAssertEqual(recorder.logged[1].signpostType, "end")
        XCTAssertTrue(recorder.logged[1].log.hasPrefix("completion:3"))

        XCTAssertEqual(recorder.logged[2].signpostType, "end")
        XCTAssertTrue(recorder.logged[2].log.hasPrefix("completion:2"))
        //XCTAssertEqual(recorder.logged[0].error, "Test Error")
    }
    
    func testTestLogColonDelimiter() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true
        let sub = Timelane.Subscription(name: "Test Subscription", logger: recorder.log)
        sub.event(value: .value("value:1"))
        sub.event(value: .value("type:123:456"))
        
        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }
        
        XCTAssertEqual(recorder.logged[0].outputTldr, "Output, Test Subscription, value:1")
        XCTAssertEqual(recorder.logged[1].outputTldr, "Output, Test Subscription, type:123:456")
    }
    
    static var allTests = [
        ("testEmitsVersion", testEmitsVersion),
        ("testEmitsEventValues", testEmitsEventValues),
        ("testEmitsSubscriptions", testEmitsSubscriptions),
        ("testTestLogColonDelimiter", testTestLogColonDelimiter),
    ]
}
