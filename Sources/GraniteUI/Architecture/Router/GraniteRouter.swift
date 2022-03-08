//
//  GraniteRouter.swift
//  
//
//  Created by 0xZala on 2/11/21.
//

import Foundation

open class GraniteRouter {
    open var route: GraniteRoute = DefaultRoute.init()
    public var home: GraniteAdAstra? = nil
    
    private var connections: [GraniteAdAstra?] = []
    
    func loading(component: GraniteAdAstra?) {
        //There has to be a better way in identifying components being deleted
        //and re-added
        connections.append(component)
    }
    
    func closing(component: GraniteAdAstra?) {
        //self.connections.removeAll(where: { "\(type(of: $0))" == "\(type(of: component))" })
    }
    
    func landHome() {
        home?.toTheStars()
    }
    
    public func request(_ route: GraniteRoute) {
        self.clean()
        
        self.route = route
        
        home?.toTheStars()
        
        GraniteLogger.info("requesting route 2 \nself:\(String(describing: self))",
                           .dependency,
                           focus: true)
    }
    
    public func clean() {
        connections.forEach { item in item?.clean() }
        connections.removeAll()
    }
    
    public init() {}
}

public struct DefaultRoute: GraniteRoute {
    public var host: GraniteAdAstra.Type?
    public var home: GraniteAdAstra.Type?
}

public protocol GraniteRoute {
    var data: String { get }
    var host: GraniteAdAstra.Type? { get }
    var home: GraniteAdAstra.Type? { get }
}

extension GraniteRoute {
    public var data: String {
        "\(self)"
    }
    
    public func convert<T: GraniteRoute>(to type: T.Type) -> T? {
        return self as? T
    }
}
