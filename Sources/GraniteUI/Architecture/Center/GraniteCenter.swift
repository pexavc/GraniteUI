//
//  GraniteCenter.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI
import Combine

// MARK: GraniteCenter
// Load Relays
// Load Expeditions
// Load Styles/Customization
//
protocol GraniteCenterDelegate: class {
    func centerWillChange()
    func centerWillClean()
    func checkOnAppearEventLinks(dependant: Bool)
}

extension GraniteCenterDelegate {
    func checkOnAppearEventLinks() {
        self.checkOnAppearEventLinks(dependant: false)
    }
}

open class GraniteCenter<T: GraniteState>: GraniteDock, GraniteControl, Reflectable, ObservableObject {
    @Published public var state: T
    
    weak var delegate: GraniteCenterDelegate?
    
    public var effectCancellables: Set<AnyCancellable> = []
    
    private var dependencyMeta: GraniteDependencyMeta
    
    lazy public var rawID: String = {
        let ptr = self
        let opaque = Unmanaged<AnyObject>.passUnretained(ptr).toOpaque()
        return "\(opaque)"
    }()
    
    public required init(_ state: T) {
        self.state = state
        self.dependencyMeta = .init()
        GraniteLogger.info("initializing - self: \(String(describing: self))", .center, symbol: "🟢")
    }
    
    public required init() {
        self.state = T.init()
        self.dependencyMeta = .init()
    }
    
    open var relays: [GraniteBaseRelay] {
        get {
            let items = Mirror(reflecting: self).children.compactMap( { $0.value as? GraniteBaseRelay })
            return items
        }
    }
    
    open var behavior: GraniteEventBehavior {
        .none
    }
    
    open var links: [GraniteLink] {
        get { [] }
    }
    
    open var expeditions: [GraniteBaseExpedition] {
        get { [] }
    }
    
    public var allRelays: [GraniteBaseRelay] {
        relays
    }
    
    public func toTheStars(_ lander: GraniteLander) {
        
        switch lander {
            case .quiet:
                break
            case .home:
                self.dependencyMeta.router?.landHome()
            default:
                self.land()
        }
    }
    
    public func locateDependencies() {
        //Keypath could store a reference
//        KeyPathCache.register(type: Self.self)
        GraniteThread.dependency.async { [weak self] in
            self?.dependencyMeta = self?.locateDependables() ?? .init()
            self?.dependencyMeta.router?.loading(component: self)
            self?.delegate?.checkOnAppearEventLinks(dependant: true)
        }
    }
    
    public func getDependency<I: GraniteDependable>(_ keypath: I.Type) -> GraniteDependency<I>? where I: GraniteDependable {
        return findDependable(keypath, meta: dependencyMeta)
    }
    
    public func land() {
        delegate?.centerWillChange()
    }
    
    public func route(_ route: GraniteRoute) {
        dependencyMeta.router?.request(route)
    }
    
    public func clean() {
//        state.clean()
        allRelays.forEach { $0.clean() }
        delegate?.centerWillClean()
        dispose()
//        self.share = nil
//        sharedRelays = []
//        dependency = .init(manager: .init(identifier: "\(String(describing: Self.self))"))
    }
    
    open func dispose() {
        
    }
    
    open var loggerSymbol: String {
        ""
    }
    
    deinit {
        clean()
        self.dependencyMeta.router?.closing(component: self)
        GraniteLogger.info("deiniting - self: \(String(describing: self))", .center, symbol: "🔴")
    }
}
