//
//  GraniteEvent.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI
import Combine

public protocol GraniteEvent: ID {
    var beam: GraniteBeamType { get }
    var behavior: GraniteEventBehavior { get }
    var debounce: Double { get }
    var async: DispatchQueue? { get }
    func compile(_ state: GraniteState)
}

extension GraniteEvent {
    public var beam: GraniteBeamType {
        .none
    }
    
    public var behavior: GraniteEventBehavior {
        .none
    }
    
    public var async: DispatchQueue? {
        nil
    }
    
    public var debounce: Double {
        .zero
    }
    
    public static var refresh: GraniteEvent {
        GraniteRefresh()
    }
}

public enum GraniteEventBehavior {
    case passthrough
    case broadcastable
    case quiet
    case none
}

extension GraniteEvent {
    
    public func compile(_ state: GraniteState) {}
    public func compile(
        expedition: GraniteBaseExpedition,
        _ state: GraniteState,
        _ connection: GraniteConnection?,
        _ cancellables: inout Set<AnyCancellable>) -> GraniteState? {
        
        guard let newState = expedition.execute(
                                event: self,
                                connection: connection,
                                state: state,
                                cancellables: &cancellables) else {
            return nil
        }
        
        return newState
    }
}

public protocol GraniteEventProcessor {
    func processEvent(_ event: GraniteEvent, _ connection: GraniteConnection?, _ state: GraniteState, _ center: GraniteAdAstra?) -> GraniteState?
}

public protocol GraniteEventResponder: GraniteEventProcessor {
    associatedtype GenericGraniteLaunch: GraniteLaunch
    var command: GenericGraniteLaunch { get set }
    func sendEvent<T: GraniteEvent>(_ event: T, _ beam: GraniteBeamType, haptic: GraniteHaptic) -> () -> ()
    func sendEvent<T: GraniteEvent>(_ event: T, _ beam: GraniteBeamType, haptic: GraniteHaptic)
}

extension GraniteEventResponder {
    public typealias selfStateType = Self.GenericGraniteLaunch.GenericGraniteState
    
    public var state: selfStateType {
        command.state
    }
    
    public var _state: Binding<selfStateType> {
        command._state
    }
    
    public func link<E: Equatable>(_ keyPath: WritableKeyPath<selfStateType, E>, event: GraniteEvent) -> Binding<E> {
        return command.link(keyPath, event: event)
    }
    
    public func route(_ newRoute: GraniteRoute) {
        command.center.route(newRoute)
    }
    
    public func route(_ newRoute: GraniteRoute) -> () -> () {
       return {
            command.center.route(newRoute)
       }
   }
    
    public func get<E: Equatable>(_ keyPath: WritableKeyPath<selfStateType, E>) -> Binding<E> {
        return command.get(keyPath)
    }
    
    public func set<E: Equatable>(_ keyPath: WritableKeyPath<selfStateType, E>, value: E) {
        command.set(keyPath, value: value)
    }
    
    public func set<D: GraniteDependable, E: Equatable>(_ keyPath: WritableKeyPath<selfStateType, E>, value: E, update: WritableKeyPath<D, E>) {
        command.set(keyPath, value: value, update: update)
    }
    
    public func update<D: GraniteDependable, E: Equatable>(_ keyPath: WritableKeyPath<D, E>, value: E, _ lander: GraniteLander = .none) {
        command.satellite?.update(keyPath, value: value, lander)
    }
    
    public var center: GraniteAdAstra {
        command.center
    }
    
    public func sendEvent<T: GraniteEvent>(_ event: T) {
        _sendEvent(event, .none, .none)
    }
    
    public func sendEvent<T: GraniteEvent>(_ event: T, haptic: GraniteHaptic = .none) {
        _sendEvent(event, .none, .none)
    }
    
    public func sendEvent<T: GraniteEvent>(_ event: T, _ beam: GraniteBeamType) {
        _sendEvent(event, beam, .none)
    }
    
    public func sendEvent<T: GraniteEvent>(_ event: T, _ beam: GraniteBeamType, haptic: GraniteHaptic) {
        _sendEvent(event, beam, haptic)
    }
    
    public func sendEvent<T: GraniteEvent>(_ event: T, _ beam: GraniteBeamType = .none, haptic: GraniteHaptic = .none) -> () -> () {
        return {
            _sendEvent(event, beam, haptic)
        }
    }
    
    public func _sendEvent<T: GraniteEvent>(_ event: T, _ beam: GraniteBeamType, _ haptic: GraniteHaptic) {
        if let async = event.async {
            async.async {
                run(event, beam)
            }
        } else {
            run(event, beam)
        }
        
        DispatchQueue.main.async {
            haptic.invoke()
        }
    }
    
    private func run<T: GraniteEvent>(_ event: T, _ beam: GraniteBeamType) {
        //GraniteThread.eventThread.addOperation {
            if let newState = processEvent(event,
                                           command as? GraniteConnection,
                                           state,
                                           center) as? selfStateType {
                command.update(newState)
            }
            
            switch beam {
            case .broadcast:
                command.center.allRelays.forEach { relay in
                    relay.beam?.request(event)
                }
            case .rebound:
                command.center.allRelays.forEach { relay in
                    if let sat = command.satellite {
                        relay.beam?.rebound(sat, event)
                    }
                }
            case .contact:
                command.satellite?.contact(event)
            default:
                break
            }
        //}
    }
}

extension GraniteEventProcessor {
    public func processEvent(_ event: GraniteEvent,
                             _ connection: GraniteConnection? = nil,
                             _ state: GraniteState,
                             _ center: GraniteAdAstra?) -> GraniteState? {
        
        
        
        guard let expedition = center?.find(event),
              let newState = event
                .compile(expedition: expedition,
                         state,
                         connection,
                         &state.effectCancellables) else {
            return nil
        }
        
        return newState
    }
    
//    public func processEvent(_ event: GraniteEvent,
//                             _ state: GraniteState,
//                             _ center: GraniteAdAstra?) -> GraniteState? {
//
//        guard let expedition = center?.find(event),
//              let newState = event
//                .compile(expedition: expedition,
//                         state,
//                         nil,
//                         &state.effectCancellables) else {
//            return nil
//        }
//
//        return newState
//    }
}
