//
//  GraniteShare.swift
//  Deprecated approach to handling sharing the component communication satellites
//
//  Created by 0xZala on 2/26/21.
//
//
//import Foundation
//import SwiftUI
//
//public class GraniteShare {
//    let dep: (DependencyManager, GraniteAdAstra.Type?, GraniteAdAstra)?
//    let relays: [GraniteBaseRelay?]?
//    let event: GraniteEvent?
//    var satellite: GraniteSatellite? = nil
//    
//    public init(_ dep: (DependencyManager, GraniteAdAstra.Type?, GraniteAdAstra)? = nil,
//                _ relay: GraniteBaseRelay? = nil,
//                _ event: GraniteEvent? = nil) {
//        
//        self.dep = dep
//        self.relays = [relay]
//        self.event = event
//    }
//    
//    public init(_ dep: (DependencyManager, GraniteAdAstra.Type?, GraniteAdAstra)? = nil,
//                _ relays: [GraniteBaseRelay?]? = nil,
//                _ event: GraniteEvent? = nil) {
//        
//        self.dep = dep
//        self.relays = relays
//        self.event = event
//    }
//    
//    public init(_ dep: (DependencyManager, GraniteAdAstra.Type?, GraniteAdAstra)? = nil) {
//        
//        self.dep = dep
//        self.relays = nil
//        self.event = nil
//    }
//    
//    public var hasRelays: Bool {
//        relays != nil
//    }
//    
//    public var hasDep: Bool {
//        dep != nil
//    }
//}
