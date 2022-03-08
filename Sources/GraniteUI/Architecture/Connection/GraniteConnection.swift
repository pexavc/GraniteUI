//
//  GraniteConnection.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation

public protocol GraniteConnection: class, ID {
    func request(_ event: GraniteEvent, _ beam: GraniteBeamType, queue: DispatchQueue)
    func push(_ input: GraniteEvent)
    func beam(_ input: GraniteEvent)
    func retrieve<T: GraniteDependable, V>(_ reference: WritableKeyPath<T, V>) -> V?
    func update<T: GraniteDependable, V>(_ reference: WritableKeyPath<T, V>,
                                          value: V,
                                          _ lander: GraniteLander)
    func destroy(_ connect: GraniteConnection)
    func download(_ value: Any, link: GraniteLink)
    func hear(event: GraniteEvent?)
    var connectionIsUpdating: Bool { get set }
}

extension GraniteConnection {
    public func destroy(_ connect: GraniteConnection) {}
}

extension GraniteConnection {
    public func request(_ event: GraniteEvent) {
        self.request(event, event.beam, queue: event.async ?? .main)
    }
    
    public func request(_ event: GraniteEvent, _ beam: GraniteBeamType) {
        self.request(event, beam, queue: event.async ?? .main)
    }
    
    public func request(_ event: GraniteEvent, queue: DispatchQueue) {
        self.request(event, event.beam, queue: queue)
    }
    
    public func update<T: GraniteDependable, V: Any>(
        _ reference: WritableKeyPath<T, V>,
        value: V) {
        
        self.update(reference, value: value, .none)
    }
}

extension GraniteConnection {
    public func hear() {
        self.hear(event: nil)
    }
}

extension GraniteConnection {
    public var rawID: String {
        let ptr = self
        let opaque = Unmanaged<Self>.passUnretained(ptr).toOpaque()
        return "\(opaque)"
    }
}

