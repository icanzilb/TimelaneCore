//
// Copyright(c) Marin Todorov 2020
// For the license agreement for this code check the LICENSE file.
//

import Foundation
import os

@available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
public class Timelane {
    
    static let version = 1
    static var log: OSLog = {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            return OSLog(subsystem: "tools.timelane.subscriptions", category: OSLog.Category.dynamicStackTracing)
        } else {
            // Fallback on a hardcoded category name.
            return OSLog(subsystem: "tools.timelane.subscriptions", category: "DynamicStackTracing")
        }
    }()

    public enum LaneType: Int, CaseIterable {
        case subscription, event
    }
    
    public struct LaneTypeOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public static let subscription: LaneTypeOptions = .init(rawValue: 1 << 0)
        public static let event: LaneTypeOptions        = .init(rawValue: 1 << 1)
        public static let all: LaneTypeOptions          = [.subscription, .event]
    }

    public typealias Logger = (_ type: OSSignpostType, _ dso: UnsafeRawPointer, _ log: OSLog, _ name: StaticString, _ signpostID: OSSignpostID, _ format: StaticString, _ arguments: CVarArg...) -> Void
    public static let defaultLogger: Logger = os_signpost
    
    public class Subscription {
        
        static var subscriptionCounter: UInt64 = 0
        private static var lock = NSRecursiveLock()
        
        private let subscriptionID: UInt64
        private let name: String
                
        private var logger: Logger
        
        public init(name: String? = nil, logger: @escaping Logger = Timelane.defaultLogger) {
            Self.lock.lock()
            Self.subscriptionCounter += 1
            subscriptionID = Self.subscriptionCounter
            Self.lock.unlock()
            
            if let name = name {
                self.name = name
            } else {
                self.name = "subscription-\(subscriptionID)"
            }
            self.logger = logger
        }
        
        public func begin(source: String = "") {
            _ = emitVersionIfNeeded
            logger(.begin, #dsohandle, log, "subscriptions", .init(subscriptionID) ,"subscribe:%{public}s###source:%{public}s###id:%{public}d", name, source, subscriptionID)
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
            
            // TODO: https://github.com/icanzilb/TimelaneCore/issues/16
            logger(.end, #dsohandle, log, "subscriptions", .init(subscriptionID), "completion:%{public}d,error:###%{public}s###", completionCode, errorMessage)
        }
        
        public func event(value event: EventType, source: String = "") {
            _ = emitVersionIfNeeded
            
            let text: String
            switch event {
            case .completion: text = ""
            case .value(let value): text = value
            case .error(let error): text = error
            case .cancelled: text = ""
            }
            
            logger(.event, #dsohandle, log, "subscriptions", .init(subscriptionID), "subscription:%{public}s###type:%{public}s###value:%{public}s###source:%{public}s###id:%{public}d", name, event.type, text.appendingEllipsis(after: 50), source, subscriptionID)
        }
        
        static var didEmitVersion = false
        
        private lazy var emitVersionIfNeeded: Void = {
            Self.lock.lock()
            defer { Self.lock.unlock() }
            
            if !Self.didEmitVersion {
                logger(.event, #dsohandle, log, "subscriptions", .exclusive, "version:%{public}d", Timelane.version)
                Self.didEmitVersion = true
            }
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
        guard count > after else { return self }
        return prefix(after).appending("...")
    }
}
