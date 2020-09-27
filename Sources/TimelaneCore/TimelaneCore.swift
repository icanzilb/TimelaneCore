//
// Copyright(c) Marin Todorov 2020
// For the license agreement for this code check the LICENSE file.
//

import Foundation
import os

/// A timelane logger that proxies events & values to another object.
@available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
public protocol ProxyLogger {
    func log(_ type: OSSignpostType, _ dso: UnsafeRawPointer, _ log: OSLog, _ name: StaticString, _ signpostID: OSSignpostID, _ format: StaticString, _ arguments: CVarArg...) -> Void
}

/// A set of core functions and types to enable higher-level
/// libraries like TimelaneCombine communicate with Instruments.
@available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
public class Timelane {
    /// The Timelane protocol version to use to talk to Instruments.
    static let version = 2
    
    /// A shared log to use for logging data to the instrument.
    static var log: OSLog = {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            return OSLog(subsystem: "tools.timelane.subscriptions", category: OSLog.Category.dynamicStackTracing)
        } else {
            // Fallback on a hardcoded category name.
            return OSLog(subsystem: "tools.timelane.subscriptions", category: "DynamicStackTracing")
        }
    }()

    /// A lane type to use when plotting data.
    public enum LaneType: Int, CaseIterable {
        /// A type of lane that plots subscriptions as color-coded bars in a horizontal bar.
        case subscription
        /// A type of lane that plots emitted values and events as placemarks on a horizontal bar.
        case event
    }
    
    /// An option set representing one or more lane types to log data to.
    public struct LaneTypeOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        /// Log to a subscription lane.
        public static let subscription: LaneTypeOptions = .init(rawValue: 1 << 0)
        /// Log to events lane.
        public static let event: LaneTypeOptions        = .init(rawValue: 1 << 1)
        /// Log to both subscriptions and events lanes.
        public static let all: LaneTypeOptions          = [.subscription, .event]
    }

    /// An alias used to describe a logger function.
    public typealias Logger = (_ type: OSSignpostType, _ dso: UnsafeRawPointer, _ log: OSLog, _ name: StaticString, _ signpostID: OSSignpostID, _ format: StaticString, _ arguments: CVarArg...) -> Void
    /// A logger to use when no logger is specified. By default it's the Timelane Instrument logger.
    public static var defaultLogger = Loggers.timelaneInstrument
        
    /// Commonly used Timelane loggers.
    public enum Loggers {
        /// The logger that pipes values & events to Timelane running in Instruments.
        public static let timelaneInstrument: Logger = os_signpost
        /// A logger that does not log anything.
        public static let disabled: Logger = devnull
        /// A logger that proxies values & events to another object.
        public static func proxy(to proxy: ProxyLogger) -> Logger { proxy.log }

        private static func devnull(_ type: OSSignpostType, _ dso: UnsafeRawPointer = #dsohandle, _ log: OSLog = OSLog(subsystem: "", category: ""), _ name: StaticString, _ signpostID: OSSignpostID, _ format: StaticString, _ arguments: CVarArg...) -> Void { }
    }
    
    /// A subscription that represents a completable or an indefinite publisher that could emit values.
    ///
    /// Subscriptions in Timelane have a "begin" event (plotted on subscription lanes) and optionally any of the following:
    ///  - cancel event - the subscription ended without emitting any completion status
    ///  - completion event - successful completion or a failure containing an error (optionally plotten on events lanes)
    ///  - value event - one or more values can be emitted by the subscription (optionally plotten on events lanes)
    public class Subscription {
        /// A counter to keep track of subscriptions.
        static var subscriptionCounter: UInt64 = 0
        private static var lock = NSRecursiveLock()
        
        private let subscriptionID: UInt64
        private let name: String
        
        private var logger: Logger
        /// Creates a new subscription with a given name that emits data to the given logger.
        /// - Parameters:
        ///   - name: A name for the subscription's lane. If `nil` a unique name is used.
        ///   - logger: A logger function to use for logging data and events. By default: `Timelane.defaultLogger`.
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
        
        /// Start a subscription and optionally provide the source that starts it.
        public func begin(source: String = "") {
            _ = emitVersionIfNeeded
            logger(.begin, #dsohandle, log, "subscriptions", .init(subscriptionID) ,"subscribe:%{public}s###source:%{public}s###id:%{public}d", name, source, subscriptionID)
        }
        
        /// End the subscription with a state of either it being cancelled, completed successfully, or failed.
        public func end(state: SubscriptionEndState) {
            var completionCode: Int
            var errorMessage: String
            
            switch state {
            case .completed:
                completionCode = SubscriptionStateCode.completed.rawValue
                errorMessage = ""
            case .error(let message):
                completionCode = SubscriptionStateCode.error.rawValue
                errorMessage = message
            case .cancelled:
                completionCode = SubscriptionStateCode.cancelled.rawValue
                errorMessage = ""
            }
            
            logger(.end, #dsohandle, log, "subscriptions", .init(subscriptionID), "completion:%{public}d###error:%{public}s", completionCode, errorMessage)
        }
        
        /// Log a value, emitted for this subscription optionally providing the source for this event.
        public func event(value event: EventType, source: String = "") {
            _ = emitVersionIfNeeded
            
            let text: String
            switch event {
            case .completion: text = ""
            case .value(let value): text = value
            case .error(let error): text = error
            case .cancelled: text = ""
            }
            
            logger(.event, #dsohandle, log, "subscriptions", .init(subscriptionID), "subscription:%{public}s###type:%{public}s###value:%{public}s###source:%{public}s###id:%{public}d", name, event.type, text, source, subscriptionID)
        }
        
        /// If `true`, the subscription already sent the protocol version it uses to Instruments.
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
        
        /// A subscription completion status.
        public enum SubscriptionEndState {
            case completed
            case error(String)
            case cancelled
        }
        
        /// A subscription event type.
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
