//
//  File.swift
//  
//
//  Created by 0xZala on 1/16/22.
//

import Foundation

public class GraniteResolver {
    private var storage = [String: GraniteDependable]()
    
    public static let shared = GraniteResolver()
    private init() {}
    
    public func add<T: GraniteDependable>(_ injectable: T) {
        let key = String(reflecting: injectable)
        storage[key] = injectable
    }

    public func resolve<T: GraniteDependable>() -> T {
        let key = String(reflecting: T.self)
        
        guard let injectable = storage[key] as? T else {
            fatalError("\(key) has not been added as an injectable object.")
        }
        
        return injectable
    }

}
