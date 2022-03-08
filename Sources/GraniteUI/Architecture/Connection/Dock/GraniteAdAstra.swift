//
//  File.swift
//  
//
//  Created by 0xZala on 1/16/22.
//

import Foundation

// MARK: GraniteAdAstra
// 'To The Stars'
// When an expedition is about to live, we have this generic
// class to easily find metadata of the expeidition, to bind it
// to its GraniteEvent, so we can execute the accompanying logic
// relative to its Component
//
public protocol GraniteAdAstra: class, ID {
    var expeditions: [GraniteBaseExpedition] { get }
    var rawID: String { get }
    func toTheStars(_ lander: GraniteLander)
    func land()
    func clean()
}

extension GraniteAdAstra {
    public static var route: GraniteAdAstra.Type {
        return Self.self
    }
    
    public func toTheStars() {
        self.toTheStars(.none)
    }
}

extension GraniteAdAstra {
    func find(_ event: GraniteEvent) -> GraniteBaseExpedition? {
        let test = expeditions.first(
            where: { $0._eventType == type(of: event) })
        
        return test
    }
}
