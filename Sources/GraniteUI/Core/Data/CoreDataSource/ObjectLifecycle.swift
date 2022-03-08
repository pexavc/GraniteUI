//
//  ObjectLifeCycle.swift
//
//
//  Created by 0xZala on 2/26/21.
//

import Foundation
import CoreData

public enum ObjectLifeCycle: Codable, Equatable {
    
    enum CodingKeys: String, CodingKey {
        case url
    }
    
    case managed(object: NSManagedObject)
    case creation
    case snapshot(objectID: NSManagedObjectID)
    case reference(uri: URL)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self)
        
        guard
            let uri: URL = try? container.decode(
                URL.self, forKey: .url)
            else {
                self = .creation
                return
        }
        self = .reference(uri: uri)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self)
        
        switch self {
        case .managed(let object):
            let uri = object.objectID.uriRepresentation()
            try container.encode(uri, forKey: .url)
        case .creation:
            break
        case .snapshot(let objectID):
            let uri = objectID.uriRepresentation()
            try container.encode(uri, forKey: .url)
        case .reference(let uri):
            try container.encode(uri, forKey: .url)
        }
    }
}

public protocol ManagedObjectLifeCycle : Codable, Equatable {
    associatedtype Object: NSManagedObject
    var lifecycle: ObjectLifeCycle { get }
    
    init?(managedObject: Object, edit: Bool)
    
    func apply(to managedObject: Object, moc: NSManagedObjectContext)
}

extension ManagedObjectLifeCycle {
    
    public func getManagedObject(
        context: NSManagedObjectContext
    ) -> Object? {
        switch lifecycle {
        case .managed(let object):
            if let typedObject = object as? Object {
                apply(to: typedObject, moc: context)
            }
            return object as? Object
        case .creation:
            let object = Object(context: context)
            apply(to: object, moc: context)
            return object
        case .snapshot(let objectID):
            return context.object(with: objectID) as? Object
        case .reference(let uri):
            if
                let objectID = context
                    .persistentStoreCoordinator?
                    .managedObjectID(forURIRepresentation: uri),
                let contextObject = context.object(
                    with: objectID) as? Object
            {
                apply(to: contextObject, moc: context)
                return contextObject
            } else { return nil }
        }
    }
    
    public static func edit(
        snapshot: Self,
        context: NSManagedObjectContext
    ) -> Self? {
        switch snapshot.lifecycle {
        case .managed(let object):
            if
                let contextObject = context.object(
                    with: object.objectID) as? Object
            {
                return Self(
                    managedObject: contextObject, edit: true)
            } else { return nil }
        case .creation:
            if
                let contextObject = snapshot.getManagedObject(
                    context: context)
            {
                return Self(
                    managedObject: contextObject, edit: true)
            } else { return nil }
        case .snapshot(let objectID):
            if
                let contextObject = context.object(
                    with: objectID) as? Object
            {
                return Self(
                    managedObject: contextObject, edit: true)
            } else { return nil }
        case .reference(let uri):
            if
                let objectID = context
                    .persistentStoreCoordinator?
                    .managedObjectID(forURIRepresentation: uri),
                let contextObject = context.object(
                    with: objectID) as? Object
            {
                return Self(
                    managedObject: contextObject, edit: true)
            } else { return nil }
        }
    }
}
