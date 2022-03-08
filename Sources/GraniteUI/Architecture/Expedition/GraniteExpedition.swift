//
//  GraniteExpedition.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI
import Combine
import CoreData

public protocol GraniteBaseExpedition {
    var _eventType: GraniteEvent.Type? { get set }
    func execute(
        event: GraniteEvent,
        connection: GraniteConnection?,
        state: GraniteState,
        cancellables: inout Set<AnyCancellable>) -> GraniteState?
}

open class GraniteExpeditionExecutable<E: GraniteExpedition>: GraniteBaseExpedition {
    public var _eventType: GraniteEvent.Type?
    private let expedition: E
    
    public init() {
        self.expedition = E()
        self._eventType = E.ExpeditionEvent.self
    }
    
    public func execute(
        event: GraniteEvent,
        connection: GraniteConnection?,
        state: GraniteState,
        cancellables: inout Set<AnyCancellable>) -> GraniteState? {
        //TODO: remove `cancellables from State` as it causes EXC_BAD_ACCESS dead locks
        //USE THIS FOR MARBLE/LA MARQUE TO NOT CRASH
        
        //Other fetch requests break though---- since its lifespan is the value of this block
//        var effectCancellables: Set<AnyCancellable> = []
        if let mutableEvent = event as? E.ExpeditionEvent,
           let mutableState = state as? E.ExpeditionState,
           let connection = connection {
            
            var publishers: AnyPublisher<GraniteEvent, Never> = Empty().eraseToAnyPublisher()
            
            expedition.reduce(
                event: mutableEvent,
                state: mutableState,
                connection: connection,
                publisher: &publishers)
            
            publishers
                .receive(on: DispatchQueue.main)
                .sink { self.sinkPublishers($0, connection, state) }
                .store(in: &cancellables)
            
            return mutableState
        } else {
            return nil
        }
    }
    
    public func sinkPublishers(_ event: GraniteEvent,
                               _ connection: GraniteConnection?,
                               _ state: GraniteState) {
//        NotificationCenter.default.post(
//            name: Notification.Name("\(event)"),
//            object: event)
        
        state.effectCancellables.forEach { $0.cancel() }
        state.effectCancellables.removeAll()
        
        connection?.request(event, event.beam, queue: event.async ?? .main)
    }
}

public protocol GraniteExpedition {
    typealias Discovery = GraniteExpeditionExecutable<Self>
    associatedtype ExpeditionEvent: GraniteEvent
    associatedtype ExpeditionState: GraniteState
    
    func reduce(
        event: ExpeditionEvent,
        state: ExpeditionState,
        connection: GraniteConnection,
        publisher: inout AnyPublisher<GraniteEvent, Never>)
    
    init()
}

extension GraniteExpedition {
    public var coreData: CoreDataManager {
        Services.shared.coreData
    }
    
    public var coreDataInstance: NSManagedObjectContext {
        Services.shared.coreDataInstance
    }
    
    public var keychain: UserDataKeychain {
        Services.shared.keychain
    }
    
    public var storage: LocalStorage {
        Services.shared.localStorage
    }
}
