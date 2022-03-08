//
//  GraniteLink.swift
//
//
//  Created by 0xZala on 2/26/21.
//

import Foundation
import SwiftUI
import Combine


//KeyPath generalization

public struct KeyPathUtils{
    public static func transcribe<S: GraniteState>(_ keypath: AnyKeyPath, _ state: inout S, value: Any) {
        switch keypath {
        case let target as WritableKeyPath<S, String>:
            guard type(of: value) == String.self else { return }
            state[keyPath: target] = value as! String
        case let target as WritableKeyPath<S, Int>:
            guard type(of: value) == Int.self else { return }
            state[keyPath: target] = value as! Int
        case let target as WritableKeyPath<S, Double>:
            guard type(of: value) == Double.self else { return }
            state[keyPath: target] = value as! Double
        default:
            break
        }
    }
}
public enum GraniteLink: ID {
    public enum When {
        case dependant
        case onAppear
        case always
    }
    
    case onAppear(GraniteEvent, When = .onAppear)
    case event(AnyKeyPath, GraniteEvent, When = .onAppear)
    case relay(AnyKeyPath, AnyKeyPath, When = .onAppear)
    
    public func dispatch<S: GraniteState>(_ state: S?,
                                          _ reference: AnyKeyPath,
                                          _ sat: GraniteConnection) {
        
        if let value = state[keyPath: reference] {//KeyPath is passing
            sat.download(value, link: self)
        }
    }
    
    func update<S: GraniteState>(_ state: inout S, _ value: Any) {
        switch self {
        case .relay(_, let target, _):
            KeyPathUtils.transcribe(target, &state, value: value)
        default:
            break
        }
    }
}
