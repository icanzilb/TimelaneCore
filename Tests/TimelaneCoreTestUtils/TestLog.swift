//
//  TestLog.swift
//
//  Created by Marin Todorov on 3/19/20.
//

import XCTest
import os

@available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
public class TestLog {
    public struct Entry: Equatable {
        public let signpostType: String
        public let log: String
        
        public init(_ type: OSSignpostType, _ log: String) {
            switch type {
            case .begin: self.signpostType = "begin"
            case .event: self.signpostType = "event"
            case .end: self.signpostType = "end"
            default: self.signpostType = ""
            }
            self.log = log
            
            fields = log.components(separatedBy: "###")
                .reduce(into: [String: String](), { (result, part) in
                    let pair = part.components(separatedBy: ":")
                    guard pair.count == 2 else { return }
                    result[pair[0]] = pair[1]
                })
        }
        
        private let fields: [String: String]
        
        public var subscribe: String? { return fields["subscribe"] }
        
        public var completion: String? { return fields["completion"] }
        public var error: String? { return fields["error"] }

        public var subscription: String? { return fields["subscription"] }
        public var type: String? { return fields["type"] }
        public var value: String? { return fields["value"] }
        public var source: String? { return fields["source"] }
        public var id: String? { return fields["id"] }
        
        public var version: String? { return fields["version"] }

        public var outputTldr: String {
            return "\(type ?? ""), \(subscription ?? ""), \(value ?? "")"
        }
    }
    
    private(set) public var logged = [Entry]()
    private let lock = NSLock()
    
    public init() {}
    
    public func log(_ type: OSSignpostType, _ dso: UnsafeRawPointer = #dsohandle, _ log: OSLog = OSLog(subsystem: "", category: ""), _ name: StaticString, _ signpostID: OSSignpostID, _ format: StaticString, _ arguments: CVarArg...) -> Void {
        lock.lock()
        defer { lock.unlock() }
        
        let template = format.withUTF8Buffer { " \(String(decoding: $0, as: UTF8.self))" }
            .components(separatedBy: "%{public}")
            .map { String($0.dropFirst()) }
        
        let value = zip(template, arguments)
            .map { "\($0)\($1)" }
            .joined()
        
        logged.append(TestLog.Entry(type, value))
    }
}
