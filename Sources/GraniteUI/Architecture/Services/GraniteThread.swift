//
//  GraniteThread.swift
//
//
//  Created by 0xZala on 2/26/21.
//

import Foundation

public struct GraniteThread {
    public static var eventQueue: OperationQueue = {
        let op: OperationQueue = .init()
        op.maxConcurrentOperationCount = 4
        op.name = "granite.event.thread.default.op"
        op.qualityOfService = .background
        return op
    }()
    
    public static var renderQueue: OperationQueue = {
        let op: OperationQueue = .init()
        op.maxConcurrentOperationCount = 1
        op.name = "granite.event.thread.default.op"
        op.qualityOfService = .background
        return op
    }()
    
    public static var dependencyQueue: OperationQueue = {
        let op: OperationQueue = .init()
        op.maxConcurrentOperationCount = 1
        op.name = "granite.dependency.thread.default.op"
        op.qualityOfService = .background
        return op
    }()
    
    public static var mainQueue: OperationQueue = {
        let op: OperationQueue = .main
        op.maxConcurrentOperationCount = 1
        op.name = "granite.event.thread.main.op"
        return op
    }()
    
    public static var event: DispatchQueue {
        .init(label: "granite.event.thread", qos: .utility)
    }
    
    public static var dependency: DispatchQueue {
        .init(label: "granite.dependency.thread", qos: .background)
    }
}
