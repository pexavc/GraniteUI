//
//  File.swift
//  
//
//  Created by 0xZala on 1/16/22.
//

import Foundation

// MARK: GraniteDock
// Logically what would be available when a ship
// docks in it's destined state.
// 
// The important items necessary of executing "Expeditions".
//
// Relay comms with other bases and the relevant expeditions
// to complete the mission.
//
public protocol GraniteDock: GraniteAdAstra {
    associatedtype GenericGraniteState: GraniteState
    
    var state: GenericGraniteState { get set }
    var relays: [GraniteBaseRelay] { get }
    var allRelays: [GraniteBaseRelay] { get }
    var expeditions: [GraniteBaseExpedition] { get }
    var links: [GraniteLink] { get }
    var behavior: GraniteEventBehavior { get }
    
    func getDependency<I: GraniteDependable>(_ keypath: I.Type) -> GraniteDependency<I>? where I: GraniteDependable
    
    func route(_ route: GraniteRoute)
    
    var loggerSymbol: String { get }
}

extension GraniteDock {
    var stateType: Self.GenericGraniteState {
        state
    }
}
