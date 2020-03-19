//
//  TestLog.swift
//
//  Created by Marin Todorov on 3/19/20.
//

import XCTest
import os
@testable import TimelaneCore

@available(macOS 10.14, iOS 12, tvOS 12, watchOS 5, *)
class TestLog {
    struct Entry: Equatable {
        let signpostType: String
        let log: String
        
        init(_ type: OSSignpostType, _ log: String) {
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
        
        var subscribe: String? { return fields["subscribe"] }
        
        var completion: String? { return fields["completion"] }
        var error: String? { return fields["error"] }

        var subscription: String? { return fields["subscription"] }
        var type: String? { return fields["type"] }
        var value: String? { return fields["value"] }
        var source: String? { return fields["source"] }
        var id: String? { return fields["id"] }
        
        var version: String? { return fields["version"] }
    }
    
    private(set) var logged = [Entry]()
    private let lock = NSLock()
    
    func log(_ type: OSSignpostType, _ dso: UnsafeRawPointer = #dsohandle, _ log: OSLog = OSLog(subsystem: "", category: ""), _ name: StaticString, _ signpostID: OSSignpostID, _ format: StaticString, _ arguments: CVarArg...) -> Void {
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
