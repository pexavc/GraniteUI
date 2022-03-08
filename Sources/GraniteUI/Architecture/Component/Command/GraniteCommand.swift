//
//  GraniteCommand.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import SwiftUI
import Combine

extension OperationQueue {
    public static var commitThread: OperationQueue = {
        let op: OperationQueue = .main
        op.name = "granite.event.thread.component.op"
        return op
    }()
}
public class EmptyState: GraniteState {
    
}

public class EmptyCenter: GraniteCenter<EmptyState> {

}

//public class EmptyCommand: GraniteCommand<EmptyCenter, EmptyState> {
//    public required init() {}
//    
//    required public init(_ state: S) {}
//}

@dynamicMemberLookup
public class GraniteCommand<C: GraniteCenter<S>, S: GraniteState>: GraniteLaunch, GraniteSatellite, GraniteEventProcessor, ObservableObject {
    
    @ObservedObject public var center: C
    
    public lazy var id: ObjectIdentifier = {
        .init(center)
    }()
    
    public subscript<T>(dynamicMember keyPath: KeyPath<C, T>) -> T {
        center[keyPath: keyPath]
    }
    
    var eventJobs: [String: QueueController] = [:]
    
//    private var signalCommand: SignalCommand = .init()
    private var anyCenterCancellable: AnyCancellable? = nil
    private var anyStateCancellable: AnyCancellable? = nil
    private var links: [GraniteLink] = []
    private var contact: GraniteContact? = nil
    private var children: [GraniteSatellite] = []
    private var injectables: [GraniteDependable] = []
    public var connectionIsUpdating: Bool = false
    
    public required init() {
        center = C.init(S.init())
        setup()
        
        GraniteLogger.info("initializing - self: \(String(describing: self))",
                           .command,
                           symbol: "\(center.loggerSymbol.isEmpty ? "" : center.loggerSymbol+" ")🟢")
    }
    
    required public init(_ state: S) {
        self.center = C.init(state)
        self.setup()
        
//        GraniteLogger.info("initializing with state - self: \(String(describing: self))",
//                           .command,
//                           symbol: "\(center.loggerSymbol.isEmpty ? "" : center.loggerSymbol+" ")🟢")
        
    }
    
    private func setup() {
        for relay in center.allRelays {
            relay.beam?.share(self)
            relay.beam?.bind(center.links)
        }
//        signalCommand = .init(center.relays, handler: handleSignal)
        
        center.delegate = self
        links = center.links
        center.locateDependencies()
    }
    
    public func commit() {
//        OperationQueue.commitThread.cancelAllOperations()
        let op: BlockOperation = .init(block: { [weak self] in
            GraniteLogger.info("stateful op is commiting - self: \(String(describing: self))", .state, focus: false)
            self?.clean()
            self?.objectWillChange.send()
        })
        
        op.name = "\(id)"
        
        let ops = OperationQueue.commitThread.operations
        
        guard ops.map({ $0.name }).contains(op.name) == false else {
            return
        }
        
        OperationQueue.commitThread.addOperations([op], waitUntilFinished: false)
    }
    
    public func commit(contact: Bool) {
        guard !contact else {
            self.contact?.parent?.commit()
            return
        }
        GraniteLogger.info("stateful op is committing from contact - self: \(String(describing: self))", .state, symbol: "🚁")
        commit()
    }
    
    public func clean() {
        self.center.clean()
        self.children.removeAll()
    }
    
    public var state: S {
        center.state
    }
    
    public var _state: Binding<S> {
        return Binding<S>(
            get: {
                self.center.state
            },
            set: {
                self.center.state = $0
                self.commit()
            }
        )
    }
    
    public func link<E: Equatable>(_ keyPath: WritableKeyPath<S, E>,
                                   event: GraniteEvent) -> Binding<E> {
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
    
    public func add(_ injectable: GraniteDependable) {
        self.injectables.removeAll()
        self.injectables.append(injectable)
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
    
    public func set<E: Equatable>(_ keyPath: WritableKeyPath<S, E>,
                                  value: E) {
        self.center.state[keyPath: keyPath] = value
        
        commit()
    }
    
    public func set<D: GraniteDependable, E: Equatable>(_ keyPath: WritableKeyPath<S, E>,
                                  value: E,
                                  update: WritableKeyPath<D, E> ) {
        self.center.state[keyPath: keyPath] = value
        self.update(update, value: value, .quiet)
        commit()
    }
    
    public func update(_ state: S, behavior: GraniteEventBehavior) {
        let newState = state
        let oldState = self.state
        self.center.state = state
        self.center.state.clean()
        _ = self.checkEventLinks(newState, oldState)
        
        //If commit runs, components and their children from
        //this target command will be re-drawn.
        guard behavior == .none else { return }
        
        self.commit()
        
        GraniteLogger.info("adding stateful op\n\(self.id)\n- self: \(String(describing: self))", .state)
    }
    
    private func checkEventLinks(_ newState: S, _ oldState: S) -> Bool {
        var isUpdating: Bool = false
        for link in links {
            switch link {
            case .event(let ref, let event, let when):
                if  when == .always,
                    let old = oldState[keyPath: ref] as? ID,
                    let new = newState[keyPath: ref] as? ID {
                    
                    if old.isNotEqual(to: new) {
                        push(event)
                        isUpdating = true
                    }
                }
            default:
                break
            }
        }
        return isUpdating
    }
    
    //A link from satellite -> relay, the relay
    //found a matching keypath and this will fire
    //updating the satellite state (components)
    //
    // WIP
    //
    public func download(_ value: Any, link: GraniteLink) {
        switch link {
        case .relay(_, _, let when):
            link.update(&center.state, value)
            switch when {
            case .dependant:
                //REFACTOR CHECK
                //self.center.toTheStars(.none)
                break
            default:
                self.center.toTheStars(.none)
                break
            }
        default:
            break
        }
    }
    
    //TODO remove?
    public func share(_ relay: GraniteBaseRelay?) {
        guard let relay = relay,
              let beam = relay.beam else { return }
        
//        signalCommand.add(beam, handler: handleSignal)
    }
    
    func handleSignal(_ input: GraniteEvent) {
        push(input)
        GraniteLogger.info("handling signal - self: \(String(describing: self))", .command)
    }
    
    func handleSignalCompletion(completion: Subscribers.Completion<GraniteSignalError>) {
        
    }
    
    public func contact(_ input: GraniteEvent) {
        self.contact?.dispatch(input)
    }
    
    public func listen(to satellite: GraniteSatellite, contact: GraniteContact.Rule) {
        self.contact = .init(parent: satellite, rule: contact)
    }
    
    public func attach(to satellite: GraniteSatellite) {
        self.children.append(satellite)
    }
    
    public func hear(event: GraniteEvent?) {
        
        self.children.forEach { child in
            child.tell(event)
        }
        
        GraniteLogger.info("hearing a potential broadcast\nchildren count: \(children.count)\n - self: \(String(describing: self))", .command)
    }
    
    public func tell(_ event: GraniteEvent?) {
        switch center.behavior {
        case .passthrough:
            self.hear(event: event)
        case .broadcastable:
            if let theEvent = event {
                self.push(theEvent)
            } else {
                self.commit()
            }
        default:
            break
        }
    }
    
    //TODO: we should add an option to selectively identify
    //the connection dispatch
    public func request(_ event: GraniteEvent, _ beam: GraniteBeamType, queue: DispatchQueue) {
        
        switch event.instance.name {
        case GraniteRefresh().instance.name:
            GraniteLogger.info("refreshing - self: \(String(describing: self))", .state, focus: true)
            self.contact?.parent?.commit()
        default:
            //Have to be careful, if the event beam type is used
            //an inifinite loop can occur
            switch beam {
            case .broadcast:
                self.beam(event)
            case .rebound:
                self.rebound(event)
            case .contact:
                self.contact(event)
            default:
                self.push(event)
            }
        }
    }
    
    public func push(_ input: GraniteEvent) {
        let thread = input.async ?? .main
        
        if !eventJobs.keys.contains(thread.label) {
            //There's a bad access potential but random
            eventJobs[thread.label] = .init(queue: thread)
        }
        if eventJobs.keys.contains(thread.label) {
            eventJobs[thread.label]?.async { [weak self] needsToStop in
                guard !needsToStop() else { return }
                guard let this = self else { return }
                
                if let newState = this.processEvent(input, this, this.state, this.center) as? S {
                    this.update(newState, behavior: input.behavior)
                }
            }
        }
    }
    
    public func beam(_ input: GraniteEvent) {
        for relay in center.allRelays {
            relay.beam?.push(input)
        }
    }
    
    public func rebound(_ input: GraniteEvent) {
        for relay in center.allRelays {
            relay.beam?.rebound(self, input)
        }
    }
    
    public func retrieve<T: GraniteDependable, V>(_ reference: WritableKeyPath<T, V>) -> V? {
        if let target = self.center.getDependency(T.self) {
            return target.wrappedValue[keyPath: reference]
        } else {
            
            return nil
        }
    }
    
    public func update<T: GraniteDependable, V>(_ reference: WritableKeyPath<T, V>,
                                                 value: V,
                                                 _ lander: GraniteLander) {
        
        if var target = self.center.getDependency(T.self) {
            target.wrappedValue[keyPath: reference] = value
            self.center.toTheStars(lander)
            
            return
        } else {
            return
        }
    }
    
    public func retrieve<V>(
        _ reference: WritableKeyPath<C, V>) -> V? {
        return self.center[keyPath: reference]
    }
    
    deinit {
        GraniteLogger.info("deiniting - self: \(String(describing: self))", .command, symbol: "\(center.loggerSymbol.isEmpty ? "" : center.loggerSymbol+" ")🔴")
    }
}

extension GraniteCommand: GraniteCenterDelegate {
    func centerWillChange() {
        commit()
    }
    
    func centerWillClean() {
        OperationQueue.commitThread.cancelAllOperations()
        
        self.eventJobs.values.forEach { queue in queue.setNeedsStopTasks() }
        self.eventJobs = [:]
    }
    
    func checkOnAppearEventLinks(dependant: Bool) {
        for link in links {
            switch link {
            case .onAppear(let event, let when):
                if dependant {
                    switch when {
                    case .dependant, .onAppear:
                        push(event)
                    default:
                        break
                    }
                } else {
                    switch when {
                    case .onAppear, .always:
                        push(event)
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        
//        DispatchQueue.main.async {
//            self.objectWillChange.send()
//        }
    }
}
