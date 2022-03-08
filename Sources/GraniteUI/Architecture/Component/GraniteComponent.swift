//
//  GraniteComponent.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI
import Combine

public protocol GraniteBaseComponent: GraniteControl {
}

public protocol GraniteComponent: View, GraniteBaseComponent, GraniteEventResponder, GraniteEmpty, Identifiable {
    var command: GenericGraniteLaunch { get set }
    init()
}

extension GraniteComponent {
    public init(state: Self.GenericGraniteLaunch
                    .GenericGraniteCenter
                    .GenericGraniteState?) {
        
        self.init()
        guard let state = state else {
            return
        }
//        let command = Self.GenericGraniteLaunch.init(state)
//        self.command = command
        if let state = state as? Self.GenericGraniteLaunch.GenericGraniteState  {
            command.update(state, behavior: .quiet)
        }
    }
    
    public init(command: Self.GenericGraniteLaunch) {
        self.init()
        self.command = command
    }
    
    public init(command: Self.GenericGraniteLaunch,
                state: Self.GenericGraniteLaunch.GenericGraniteCenter.GenericGraniteState) {
        
        self.init()
        self.command = command
        
        if let state = state as? Self.GenericGraniteLaunch.GenericGraniteState  {
            command.update(state)
        }
    }
}

extension GraniteComponent {
    public var body: some View { EmptyView.init() }
}

extension GraniteComponent {
    public func listen(to satellite: GraniteSatellite,
                       _ contact: GraniteContact.Rule = .none) -> Self {
        (command as? GraniteSatellite)?.listen(to: satellite, contact: contact)
        return self
    }
    
    public func attach(to satellite: GraniteSatellite) -> Self {
        if let sat = (command as? GraniteSatellite) {
            satellite.attach(to: sat)
        }
        return self
    }
}

//MARK: Relays
extension GraniteComponent {
    public func relays(_ find: [GraniteBaseRelay.Type]) -> [GraniteBaseRelay?] {
        
        var relays: [GraniteBaseRelay?] = []
        
        for relayType in find {
            relays.append(command.center.allRelays.first(where: { type(of: Mirror(reflecting: $0).subjectType) == type(of: relayType) }))
        }
        
        return relays
    }
    
    public var relays: [GraniteBaseRelay?] {
        command.center.allRelays
    }
    
    public func relay(_ find: GraniteBaseRelay.Type) -> (GraniteBaseRelay?) {
        
        return command.center.allRelays.first(where: { type(of: Mirror(reflecting: $0).subjectType) == type(of: find) })
    }
}

extension GraniteComponent {
    public func injectPayload<T: GraniteDependable, O: Any>(
        _ reference: KeyPath<GenericGraniteLaunch.GenericGraniteCenter, T>,
        target: KeyPath<T, O>) -> GranitePayload? {
        
        let depT = command.center[keyPath: reference]
        let value = depT[keyPath: target]
        return .init(object: value)
    }
    
    public func inject<T: GraniteDependable, O>(
        _ reference: KeyPath<GenericGraniteLaunch.GenericGraniteCenter, T>,
        target: KeyPath<T, O>) -> O? {
        let depT = command.center[keyPath: reference]
        return depT[keyPath: target]
    }
}

extension GraniteComponent {
    public func payload(_ object: GranitePayload?) -> Self {
        state.payload = object
        return self
    }
}

public class GraniteSubject<T> {
    let subject = CurrentValueSubject<T?, Never>(nil)
    
    func listen() {
        _ = subject
            .sink(receiveValue: { GraniteLogger.info("\(String(describing: $0))", .signal) })
    }
    
    init() {
        listen()
    }
}

extension GraniteComponent {
    public var isDependancyEmpty: Bool {
        false
    }
    
    public var emptyText: String {
        ""
    }
    
    public var emptyPayload: GranitePayload? {
        nil
    }
}

#if canImport(UIKit)
extension View {
  public func hideKeyboard() {
      UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
#endif

