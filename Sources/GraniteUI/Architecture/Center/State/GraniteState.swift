//
//  GraniteState.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI
import Combine

// MARK: GraniteState
// When an expedition completes a payload may be
// necessary to pass on to child components,
// as a default attribute to all States
// it can be bound via `.payload(..)` to a component
// during `body: some View` calls
//
// The child, can easiy access via setting a new State variable
// that returns the object as the set type they expect.
//
public struct GranitePayload: Equatable, Hashable {
    public static func == (lhs: GranitePayload, rhs: GranitePayload) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    public let uuid: UUID = .init()
    public let object: Any?
    
    public init(object: Any?) {
        self.object = object
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.uuid)
    }
    
    public static var empty: GranitePayload {
        .init(object: nil)
    }
}

extension OperationQueue {
    public static var stateThread: OperationQueue = {
        var op: OperationQueue = .main
        op.name = "granite.event.thread.state.op"
        return op
    }()
}

// MARK: GraniteState
// All dynamic variables that could change
// a components behavior and appearance
//
open class GraniteState: ObservableObject {
    public var payload: GranitePayload? = nil
    public var effectCancellables: Set<AnyCancellable> = []
    
    public required init() {}
    
    public func clean() {
        //DEV: TODO: may have solved cancellable storage
        //issue with EXC_BAD_ACCESS
        OperationQueue.stateThread.addOperation { [weak self] in
            _ = self?.effectCancellables.map { $0.cancel() }
            self?.effectCancellables.removeAll()
        }
    }
}

public enum GraniteSignalError: Error {
    case test
}
