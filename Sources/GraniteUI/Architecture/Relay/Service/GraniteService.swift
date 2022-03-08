//
//  GraniteService.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI
import Combine

extension OperationQueue {
    public static var relayThread: OperationQueue = {
        let op: OperationQueue = .main
        op.name = "granite.event.thread.relay.op"
        return op
    }()
}

public typealias GraniteSignalSubject = PassthroughSubject<GraniteEvent, GraniteSignalError>

// MARK: GraniteService
// The GraniteRelay's version of the GraniteCommand.
//
open class GraniteService<C: GraniteCenter<S>, S: GraniteState>: GraniteLaunch, GraniteBeam, GraniteEventProcessor, ObservableObject {
    
    @ObservedObject public var center: C
    
    public var events: [GraniteEvent] = []
//    public var subject = GraniteSignalSubject()
    
    //If a GraniteSatellite (Component) would like to connect
    //it will be stored in this array, and pushed beams during
    //events, that it's currently hosting as Expeditions.
    //
    //A simpler method than sharing a specific Event, in case of
    //custom payload requirements.
    //
    weak private var connection: GraniteConnection?
    
    //Isolated envorinment for managing Beam publishers
    //and Subscribers, of various active relays.
    //
    //GraniteRelays/Services can have Child Relays as well.
    //
//    private var signalCommand: SignalCommand = .init()
    
    private var links: [GraniteLink] = []
    private var rebound: GraniteRebound? = nil
    
    public var connectionIsUpdating: Bool = false
    private var anyCancellable: AnyCancellable? = nil
//    private var effectCancellables: Set<AnyCancellable> = []
    public required init() {
        center = C.init(S.init())
        setup()
        
        GraniteLogger.info("initializing - self: \(String(describing: self))", .relay, symbol: "🟢")
    }
    
    required public init(_ state: S) {
        self.center = C.init(state)
        self.setup()
        
        GraniteLogger.info("initializing with state - self: \(String(describing: self))", .relay, symbol: "🟢")
    }
    
    private func setup() {
//        signalCommand = .init(center.relays, handler: handleSignal)
    }
    
    public func commit() {
        OperationQueue.relayThread.addOperation({ [weak self] in
            self?.objectWillChange.send()
        })
    }
    
    public var state: S {
        return center.state
    }
    
    public var _state: Binding<S> {
        return Binding<S>(
            get: {
                self.center.state
            },
            set: {
                self.center.state = $0
            }
        )
    }
    
    public func link<E: Equatable>(_ keyPath: WritableKeyPath<S, E>, event: GraniteEvent) -> Binding<E> {
        return Binding<E>(
            get: {
                self.center.state[keyPath: keyPath]
            },
            set: {
                self.center.state[keyPath: keyPath] = $0
                self.push(event)
            }
        )
    }
    
    public func get<E: Equatable>(_ keyPath: WritableKeyPath<S, E>) -> Binding<E> {
        return Binding<E>(
            get: {
                self.center.state[keyPath: keyPath]
            },
            set: {
                self.center.state[keyPath: keyPath] = $0
            }
        )
    }
    
    public func set<E: Equatable>(_ keyPath: WritableKeyPath<S, E>, value: E) {
        self.center.state[keyPath: keyPath] = value
        commit()
    }
    
    public func set<D: GraniteDependable, E: Equatable>(_ keyPath: WritableKeyPath<S, E>,
                                  value: E,
                                  update: WritableKeyPath<D, E> ) {
        self.center.state[keyPath: keyPath] = value
        //REFACTOR CHECK
//        self.update(update, value: value, .quiet)
        commit()
    }
    
    
    //Updates the @published State of the center
    //same logic as a component
    //
    public func update(_ state: S, behavior: GraniteEventBehavior) {
        center.state = state
        checkRelayLinks()
    }
    
    private func checkRelayLinks() {
        for link in links {
            switch link {
            case .relay(let ref, _, _):
                if let sat = self.connection {
                    link.dispatch(self.state, ref, sat)
                    GraniteLogger.info("dispatching links", .relay, symbol: "🚁")
                }
            default:
                break
            }
        }
    }
    
    //Updates the events this Relay is currently
    //beaming information to
    //
    public func update(events: [GraniteEvent]) {
        self.events = events
    }
    
    //New specific events can be added to be signaled with a Beam
    //
    public func share(_ event: GraniteEvent) {
        guard events.first(where: { $0.id == event.id }) == nil else {
            return
        }
        
        events.append(event)
    }
    
    //GraniteSatellites or other GraniteBeams can be added for
    //beamed info relative to this service. With the current
    //event set
    //
    public func share(_ connection: GraniteConnection?) {
        self.connection = connection
    }
    
    //Signal received, let's push a beam.
    //
    func handleSignal(_ input: GraniteEvent) {
        push(input)
    }
    
    //If the SignalCommand is of not `.unlimited` a completion
    //callback can be handled here, or if an error is reported
    //
    func handleSignalCompletion(completion: Subscribers.Completion<GraniteSignalError>) {
        
    }
    
    //Bindable variables from satellite -> relay
    //activated via the link() overridable in component classes
    //
    public func bind(_ links: [GraniteLink]){
        self.links = links
    }
    
    public func request(_ event: GraniteEvent,
                        _ beam: GraniteBeamType,
                        queue: DispatchQueue) {
        
        OperationQueue.relayThread.addOperation({ [weak self] in
            switch beam {
            case .broadcast:
//                self?.subject.send(event)
//                self?.beam(event)
                self?.rebound?.connection.request(event, .none, queue: queue)//.connection.request(event, .broadcast, queue: queue)
            case .rebound:
                switch self?.rebound?.beamType {
                case .broadcast:
                    self?.rebound?.connection.request(event, .rebound, queue: queue)//.connection.request(event, .broadcast, queue: queue)
                case .rebound:
                    self?.rebound?.connection.push(event)
                    self?.rebound = nil
                default:
                    break
                }
            default:
                self?.push(event)
            }
        })
    }
    
    public func rebound(_ connection: GraniteConnection,
                        _ input: GraniteEvent) {
        
        self.rebound = .init(connection)
        push(input)
    }
    
    public func rebound(_ rebound: GraniteRebound,
                        _ input: GraniteEvent) {
        self.rebound = rebound
        push(input)
    }
    
    public func push(_ input: GraniteEvent) {
        if let newState = self.processEvent(input, self, self.state, self.center) as? S {
            self.update(newState)
        }
    }
    
    public func beam(_ input: GraniteEvent) {
        connection?.request(input)
    }
    
    public func update<T, V>(_ reference: WritableKeyPath<T, V>, value: V, _ lander: GraniteLander) where T : GraniteDependable {
        
    }
    
    public func update<T, V>(_ reference: WritableKeyPath<T, V>, value: V) where T : GraniteDependable {
        
    }
    
    public func retrieve<T, V>(_ reference: WritableKeyPath<T, V>) -> V? where T : GraniteDependable {
        return nil
    }
    
    public func destroy(_ connect: GraniteConnection) {
        if connection?.id == connect.id {
            self.connection = nil
        }
    }
    
    public func download(_ value: Any, link: GraniteLink) {}
    public func hear(event: GraniteEvent?) {}
    
    public func clean() {
        self.connection = nil
        self.links = []
        center.clean()
        events = []
    }
    
    deinit {
        GraniteLogger.info("deiniting - self: \(String(describing: self))", .relay, symbol: "🔴")
    }
}
