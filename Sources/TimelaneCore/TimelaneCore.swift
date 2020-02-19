//
// Copyright(c) Marin Todorov 2020
// For the license agreement for this code check the LICENSE file.
//

import Foundation
import os

public class Timelane {
    
    static let version = 1
    static let log = OSLog(subsystem: "tools.timelane.subscriptions", category: OSLog.Category.dynamicStackTracing)
    
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
            _ = Self.emitVersionIfNeeded
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
            case .cancelled:
                completionCode = SubscriptionStateCode.cancelled.rawValue
                errorMessage = ""
            }
            
            os_signpost(.end, log: log, name: "subscriptions", signpostID: .init(subscriptionID), "completion:%{public}d,error:###%{public}s###", completionCode, errorMessage)
        }
        
        public func event(value event: EventType, source: String = "") {
            _ = Self.emitVersionIfNeeded
            
            let text: String
            switch event {
            case .completion: text = ""
            case .value(let value): text = value
            case .error(let error): text = error
            case .cancelled: text = ""
            }
            
            os_signpost(.event, log: log, name: "subscriptions", signpostID: .init(subscriptionID), "subscription:%{public}s###type:%{public}s###value:%{public}s###source:%{public}s###id:%{public}d", name, event.type, text.appendingEllipsis(after: 50), source, subscriptionID)
        }
        
        static private var didEmitVersion = false
        
        static var emitVersionIfNeeded: Void = {
            os_signpost(.event, log: log, name: "subscriptions", signpostID: .exclusive, "version:%{public}d", Timelane.version)
        }()
        
        private enum SubscriptionStateCode: Int {
            case active = 0
            case cancelled = 1
            case error = 2
            case completed = 3
        }
        
        public enum SubscriptionEndState {
            case completed
            case error(String)
            case cancelled
        }
        
        public enum EventType {
            case value(String), completion, error(String), cancelled
            
            var type: String {
                switch self {
                case .completion: return "Completed"
                case .error: return "Error"
                case .value: return "Output"
                case .cancelled: return "Cancelled"
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
