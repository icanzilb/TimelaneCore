//
// Copyright(c) Marin Todorov 2020
// For the license agreement for this code check the LICENSE file.
//

import Foundation
import os

public class Timelane {
    static let log = OSLog(subsystem: "tools.timelane.subscriptions", category: OSLog.Category.dynamicStackTracing)
    static let version = 1
    
    public class Subscription {
        
        private static var subscriptionCounter: UInt64 = 0
        private static var lock = NSRecursiveLock()
        
        private let subscriptionID: UInt64
        private let name: String
        
        public init(name: String? = nil) {
            Self.lock.lock()
            Self.subscriptionCounter += 1
            subscriptionID = Self.subscriptionCounter
            Self.lock.unlock()
            
            if let name = name {
                self.name = name
            } else {
                self.name = "subscription-\(subscriptionID)"
            }
        }
        
        public func begin(source: String = "") {
            emitVersionIfNeeded()
            os_signpost(.begin, log: log, name: "subscriptions", signpostID: .init(subscriptionID) ,"subscribe:%{public}s###source:%{public}s###id:%{public}d", name, source, subscriptionID)
        }
        
        public func end(state: SubscriptionEndState) {
            var completionCode: Int
            var errorMessage: String
            
            switch state {
            case .completed:
                completionCode = SubscriptionStateCode.completed.rawValue
                errorMessage = ""
            case .error(let message):
                completionCode = SubscriptionStateCode.error.rawValue
                errorMessage = message.appendingEllipsis(after: 50)
            }
            
            os_signpost(.end, log: log, name: "subscriptions", signpostID: .init(subscriptionID), "completion:%{public}d,error:###%{public}s###", completionCode, errorMessage)
        }
        
        public func event(value event: EventType, source: String = "") {
            emitVersionIfNeeded()
            
            let text: String
            switch event {
            case .completion: text = ""
            case .value(let value): text = value
            case .error(let error): text = error
            }
            
            let valueDescription = text.appendingEllipsis(after: 50)
            os_signpost(.event, log: log, name: "subscriptions", signpostID: .init(subscriptionID), "subscription:%{public}s###type:%{public}s###value:%{public}s###source:%{public}s###id:%{public}d", name, event.type, valueDescription, source, subscriptionID)
        }
        
        static private var didEmitVersion = false
        
        func emitVersionIfNeeded() {
            Self.lock.lock()
            defer { Self.lock.unlock() }
            
            guard !Self.didEmitVersion else { return }
            
            Self.didEmitVersion = true
            os_signpost(.event, log: log, name: "subscriptions", signpostID: .exclusive, "version:%{public}d", Timelane.version)
        }
        
        private enum SubscriptionStateCode: Int {
            case active = 0
            case cancelled = 1
            case error = 2
            case completed = 3
        }
        
        public enum SubscriptionEndState {
            case completed
            case error(String)
        }
        
        public enum EventType {
            case value(String), completion, error(String)
            
            var type: String {
                switch self {
                case .completion: return "Completed"
                case .error: return "Error"
                case .value: return "Output"
                }
            }
        }
    }
}

fileprivate extension String {
    func appendingEllipsis(after: Int) -> String {
        guard count > 50 else { return self }
        return prefix(50).appending("...")
    }
}
