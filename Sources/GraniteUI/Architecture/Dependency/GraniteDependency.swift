//
//  File.swift
//  
//
//  Created by 0xZala on 1/16/22.
//

import Foundation

// MARK: GraniteDependency
// Environment Pathing or simple dependency
// injection to maintain consitency with certain
// variables such as a search query that is part of
// a child search bar component
//
public protocol GraniteDependencyManager {}

public struct GraniteDependencyMeta {
    struct DependencyMeta {
        var location: Int
        var label: String?
    }
    
    var meta: [DependencyMeta] = []
    var router: GraniteRouter? = nil
}

@propertyWrapper
public struct GraniteDependency<T: GraniteDependable> {
    public var wrappedValue: T
    
    public init() {
        wrappedValue = GraniteResolver.shared.resolve()
    }
}
