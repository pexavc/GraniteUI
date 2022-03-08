//
//  File.swift
//  
//
//  Created by 0xZala on 1/16/22.
//

import Foundation
import SwiftUI

// MARK: GraniteLaunch
// Logically what would be available before/during a ship's
// launch from Base.
//
// The command "center" handles all `backend` facilities to organize
// what's available in the high level for GraniteComponents and
// GraniteRelays.
//
public protocol GraniteLaunch {
    associatedtype GenericGraniteCenter: GraniteDock
    associatedtype GenericGraniteState: GraniteState
    
    var center: GenericGraniteCenter { get set }
    var state: GenericGraniteState { get }
    var _state: Binding<GenericGraniteState> { get }
    func link<E: Equatable>(_ keyPath: WritableKeyPath<GenericGraniteState, E>, event: GraniteEvent) -> Binding<E>
    func get<E: Equatable>(_ keyPath: WritableKeyPath<GenericGraniteState, E>) -> Binding<E>
    func set<E: Equatable>(_ keyPath: WritableKeyPath<GenericGraniteState, E>, value: E)
    func set<D: GraniteDependable, E: Equatable>(_ keyPath: WritableKeyPath<GenericGraniteState, E>,
                                  value: E,
                                  update: WritableKeyPath<D, E>)
    func update(_ state: GenericGraniteState, behavior: GraniteEventBehavior)
    
    init()
    init(_ state: GenericGraniteCenter.GenericGraniteState)
}

extension GraniteLaunch {
    var satellite: GraniteSatellite? {
        self as? GraniteSatellite
    }
    
    public func update(_ state: GenericGraniteState) {
        self.update(state, behavior: .none)
    }
}
