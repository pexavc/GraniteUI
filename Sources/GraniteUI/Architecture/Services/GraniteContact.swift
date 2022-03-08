//
//  GraniteContact.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation

public class GraniteContact {
    public enum Rule {
        case stop
        case none
    }
    
    weak public var parent: GraniteSatellite?
    public var rule: Rule
    
    public init(parent: GraniteSatellite?, rule: Rule) {
        self.parent = parent
        self.rule = rule
    }
    
    public func dispatch(_ input: GraniteEvent) {
        parent?.request(input, input.beam)
        switch rule {
        case .none:
            parent?.contact(input)
        default:
            break
        }
    }
}


