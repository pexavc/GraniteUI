//
//  GraniteControl.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation


//public typealias GraniteControl = GraniteBaseComponent & GraniteBaseRelay

public protocol GraniteControl: ID {}

extension GraniteControl {
    public func locateDependables() -> GraniteDependencyMeta {
        var metas: [GraniteDependencyMeta.DependencyMeta] = []
        
        let mirror = Mirror(reflecting: self)
        let children = mirror.children
        
        var router: GraniteRouter?
        for (i, child) in children.enumerated() {
            
            if let item = Mirror(reflecting: child.value).descendant("wrappedValue") as? GraniteDependable  {
                let meta: GraniteDependencyMeta.DependencyMeta = .init(location: i,
                                                                       label: "\(item)")
                
                if router == nil {
                    for potentialRouter in Mirror(reflecting: item).children {
                        if let routerFound = potentialRouter.value as? GraniteRouter {
                            router = routerFound
                            break
                        }
                    }
                }
                metas.append(meta)
            }
        }
        
        return .init(meta: metas, router: router)
    }
    public func findDependable<T: GraniteDependable>(_ dep: T.Type, meta: GraniteDependencyMeta) -> GraniteDependency<T>? {
        
        let target = ("\(dep)").lowercased()
        if let targetMeta = meta.meta.first(where: { ($0.label?.lowercased() ?? "").contains(target) }) {
            let mirror = Mirror(reflecting: self)
            let children = mirror.children
            guard children.count > targetMeta.location else { return nil }
            let child = Array(children)[targetMeta.location]
            
            return child.value as? GraniteDependency<T>
        } else {
            return nil
        }
        
//        var potentialWrapped: Any? = nil
    

        ///
//        // We could store the label initially or the index
//        // or we could store the type
//        // either way we should make it so it's O(n) search
//
//        for child in children {
//            //potentialCommand = Mirror(reflecting: child.value).descendant("wrappedValue") as? T
//            potentialWrapped = child.value as? GraniteDependency<T>
//            if potentialWrapped != nil {
//                break
//            }
//        }
        
//        return potentialWrapped as? GraniteDependency<T>
        //        guard let _command = potentialCommand else { return nil }
        //
        //        var potentialCenter: Any? = nil
        //
        //        let mirrorCommand = Mirror(reflecting: _command)
        //        let childrenCommand = mirrorCommand.children
        //
        //        for child in childrenCommand {
        //            if potentialCenter == nil {
        //                let mirrorService = Mirror(reflecting: child.value)
        //                potentialCenter = mirrorService.descendant("wrappedValue")
        //            } else {
        //                break
        //            }
        //        }
        //
        //        guard let _center = potentialCenter else { return nil }
        //
        //        return _center as? T
    }
    
    public func mirrorThis<T>(_ relate: Any?, dont: T.Type) -> T? {
        //        guard let relate = relate else { return nil }
        
        var potentialCommand: Any? = nil
        
        
        
        //        let mirror = Mirror(reflecting: relate)
        //        let children = mirror.children
        //        for child in children {
        //            if potentialCommand == nil {
        //                potentialCommand = Mirror(reflecting: child.value).descendant("_command")
        //            } else {
        //                break
        //            }
        //        }
        
        guard let _command = potentialCommand else { return nil }
        
        var potentialCenter: Any? = nil
        
        let mirrorCommand = Mirror(reflecting: _command)
        let childrenCommand = mirrorCommand.children
        
        for child in childrenCommand {
            if potentialCenter == nil {
                let mirrorService = Mirror(reflecting: child.value)
                potentialCenter = mirrorService.descendant("_center")
            } else {
                break
            }
        }
        
        guard let _center = potentialCenter else { return nil }
        
        let mirrorCenter = Mirror(reflecting: _center).descendant("wrappedValue")
        
        return mirrorCenter as? T
    }
}

protocol DefaultValueProvider
{
    init()
}

public struct HashedType : Hashable
{
    public let hashValue: Int
    
    public init(_ type: Any.Type)
    {
        hashValue = unsafeBitCast(type, to: Int.self)
    }
    
    public init<T>(_ pointer: UnsafePointer<T>)
    {
        hashValue = pointer.hashValue
    }
    
    public static func == (lhs: HashedType, rhs: HashedType) -> Bool
    {
        return lhs.hashValue == rhs.hashValue
    }
}

protocol Reflectable : DefaultValueProvider { }

extension Reflectable
{
    static var keyPaths: [String : AnyKeyPath]?
    {
        return KeyPathCache.keyPaths(for: Self.self)
    }
    
    fileprivate subscript(checkedMirrorDescendant key: String) -> Any
    {
        let hashedType = HashedType(type(of: self))
        
        return KeyPathCache.mirrors[hashedType]!.descendant(key)!
    }
    
    fileprivate subscript(get key: String) -> Any
    {
        let hashedType = HashedType(type(of: self))
        
        return KeyPathCache.mirrors[hashedType]!.descendant(key)!
    }
    
    fileprivate func check(key: String) -> Bool
    {
        let hashedType = HashedType(type(of: self))
        
        return (KeyPathCache.mirrors[hashedType]?.descendant(key) as? GraniteDependable) != nil
    }
}

class KeyPathCache
{
    fileprivate static var mirrors: [HashedType : Mirror] = .init()
    
    private static var items: [HashedType : [String : AnyKeyPath]] = .init()
    
    static func keyPaths<typeT : Reflectable>(for type: typeT.Type) -> [String : AnyKeyPath]?
    {
        let hashedType = HashedType(type)
        
        return items[hashedType]
    }
    
    static func register<typeT : Reflectable>(type: typeT.Type)
    {
        let hashedType = HashedType(type)
        
        if mirrors.keys.contains(hashedType)
        {
            return
        }
        
        let subject = typeT()
        let mirror = Mirror(reflecting: subject)
        
        mirrors[hashedType] = mirror
        
        var keyPathsDictionary: [String : AnyKeyPath] = .init()
        
        for case (let key?, let child) in mirror.children
        {
            
            if let item = Mirror(reflecting: child)
                            .descendant("wrappedValue") as? GraniteDependable  {
                
                keyPathsDictionary["\(item)"] = \typeT.[get: key]
                
            }
            
        }
        
        items[hashedType] = keyPathsDictionary
    }
}
