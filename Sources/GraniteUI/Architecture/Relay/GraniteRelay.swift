//
//  GraniteRelay.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI
import Combine

// MARK: GraniteBaseRelay
// The base `relay` class, providing the beam `ping` to relevant
// satellites who would like to listen in.
//
// an id, for equatables
//
// the `subject` that a subscription is being created for
//
public protocol GraniteBaseRelay: GraniteControl {
    var beam: GraniteBeam? { get }
    func clean()
//    var subject: GraniteSignalSubject? { get }
}

// MARK: GraniteRelay
// Houses the `Command` unit for the Service being created
//
// setup(), should be administered in relative Services'
// before Relay begins beaming.
//
public protocol GraniteRelay: GraniteBaseRelay, GraniteEventResponder {
    var command: GenericGraniteLaunch { get set }
    
    func setup()
    init()
    init(_ event: GraniteEvent)
    init(_ events: [GraniteEvent])
    init(latch: Bool)
}

// MARK: ext. GraniteRelay
// Helpful abstraction to be made available for
// processing data required for events in `some View` body
// closures, aka attaching to new Components.
//
extension GraniteRelay {
    public init(state: Self.GenericGraniteLaunch
                    .GenericGraniteCenter
                    .GenericGraniteState?) {
        
        self.init()
        guard let state = state else {
            return
        }
        let command = Self.GenericGraniteLaunch.init(state)
        self.command = command
        self.setup()
    }
    
    //Accessor for command, as a `GraniteBeam`
    //avoids associatedType protocol limitations
    //
    public var beam: GraniteBeam? {
        command as? GraniteBeam
    }
    
    //Sends a global notification
    //
    public func sendRelay<T: GraniteEvent>(_ event: T) {
        event.relay.notify()
    }
    
    //Accessor for the live subject, to query either
    //active subscriptions or cancellables
    //
//    public var subject: GraniteSignalSubject? {
//        beam?.subject
//    }
    
    //A single event can be stored during init, to receive
    //beams independantly
    //
    public init(_ event: GraniteEvent) {
        self.init()
        beam?.update(events: [event])
        self.setup()
    }
    
    //Multiple events can be stored during init, to receive
    //beams independantly
    //
    public init(_ events: [GraniteEvent]) {
        self.init()
        beam?.update(events: events)
        self.setup()
    }
    
    //Latch is a WIP.
    //The idea is to have Relays, have the ability to
    //hold off on beaming for specific Events in its' queue
    //or to re-enable, based on the component requesting
    //the Service attachment.
    //
    public init(latch: Bool) {
        self.init()
        self.setup()
    }
    
    public var body: some View { EmptyView.init() }
}

// MARK: GraniteBeam
// The core functions that assists in dynamic component ]
// sharing for a single GraniteRelay, allowing that Service
// in particular to fire beams throughout an environment
// cost-effectively.
//
public protocol GraniteBeam: GraniteConnection {
//    var subject: GraniteSignalSubject { get set }
    var events: [GraniteEvent] { get set }
    
    func share(_ event: GraniteEvent)
    func share(_ connection: GraniteConnection?)
    func update(events: [GraniteEvent])
    
    func bind(_ links: [GraniteLink])
    
    func rebound(_ connection: GraniteConnection, _ input: GraniteEvent)
    func rebound(_ rebound: GraniteRebound, _ input: GraniteEvent)
    func clean()
}

extension GraniteBeam {
    public var key: String {
        ""
    }
}

public enum GraniteBeamType {
    case rebound
    case broadcast
    case contact
    case none
}

public struct GraniteRebound {
    public let connection: GraniteConnection
    public let beamType: GraniteBeamType
    
    public init(_ connection: GraniteConnection,
                _ beamType: GraniteBeamType = .rebound) {
        self.connection = connection
        self.beamType = beamType
    }
}
