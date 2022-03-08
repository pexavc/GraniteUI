//
//  SignalCommander.swift
//  Deprecated until further notice. 
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI
import Combine

public class SignalCommand {
    private var activeSignals: [SignalSubscription] = []
    
    private var handler: ((GraniteEvent) -> Void)? = nil
    
    public init() {}
    
    public init(_ relays: [GraniteBaseRelay],
                handler: @escaping ((GraniteEvent) -> Void)){
        self.handler = handler
//        for relay in relays {
//            if let subject = relay.subject {
//
//                let subscription: SignalSubscription = .init(
//                    subject,
//                    completion: handleSignalCompletion,
//                    receive: handleSignal)
//
//                activeSignals.append(subscription)
//            }
//        }
    }
    
    public init(_ beam: GraniteBeam, handler: @escaping ((GraniteEvent) -> Void)){
        self.handler = handler
        
//        let subscription: SignalSubscription = .init(
//            beam.subject,
//            completion: handleSignalCompletion,
//            receive: handleSignal)
//
//        activeSignals.append(subscription)
    }
    
    public func add(_ beam: GraniteBeam, handler: @escaping ((GraniteEvent) -> Void)){
        self.handler = handler
        
//        let subscription: SignalSubscription = .init(
//            beam.subject,
//            completion: handleSignalCompletion,
//            receive: handleSignal)
//        
//        activeSignals.removeAll(where: { $0.subscription == subscription.subscription })
//        
//        activeSignals.append(subscription)
    }
    
    func handleSignal(_ input: GraniteEvent) {
        switch input.beam {
        case .broadcast, .rebound:
            handler?(input)
            
        default:
            break
        }
    }
    
    func handleSignalCompletion(completion: Subscribers.Completion<GraniteSignalError>) {
        
    }
    
    func destroy() {
        for signal in activeSignals {
            signal.subscription?.cancel()
        }
    }
    
//    deinit {
//        destroy()
//    }
}
