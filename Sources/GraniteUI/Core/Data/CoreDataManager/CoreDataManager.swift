//
//  CoreDataManager.swift
//
//
//  Created by 0xZala on 2/26/21.
//

import CoreData
import Foundation

public enum CoreDataThread {
    case background
    case main
}

public class CoreDataManager: Equatable {
    public static func == (
        lhs: CoreDataManager,
        rhs: CoreDataManager
    ) -> Bool {
        lhs === rhs
    }
    
    public enum Error: Swift.Error {
        case couldNotWriteModelResources(underlying: Swift.Error)
        case couldNotMakeModelBundle
        case couldNotCreateManagedObjectModel
    }
    
    public let persistentContainer: NSPersistentContainer
    
    private let migrationEngine: CoreDataMigrationEngine
    
    private let storeType: String
    
    public var background: NSManagedObjectContext {
        let context = self.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return context
    }
    
    public lazy var main: NSManagedObjectContext = {
        let context = self.persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        return context
    }()
    
    public let name: String
    public init(
        name: String,
        storeType: String = NSSQLiteStoreType,
        migrationEngine: CoreDataMigrationEngine = .init()
    ) {
        self.name = name
        self.persistentContainer = CoreDataManager.makePersistentContainer(name: name)
        self.migrationEngine = migrationEngine
        self.storeType = storeType
        setup({})
    }
    
    public init(){
        self.name = "undefined"
        self.persistentContainer = .init()
        self.migrationEngine = .init()
        self.storeType = .init()
    }
    
    public static var storeURL: URL {
        dataDirectory.appendingPathComponent("variant_0000.sqlite")
    }
    
    public static func makePersistentContainer(
        name: String,
        storeType: String = NSSQLiteStoreType
    ) -> NSPersistentContainer  {
        
        let container = NSPersistentContainer(name: name)
        
        let storeURL: URL = CoreDataManager.storeURL
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.url = storeURL
            storeDescription.type = storeType
            storeDescription.shouldInferMappingModelAutomatically = false
            storeDescription.shouldMigrateStoreAutomatically = false
            
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        return container
    }

    public static var cacheDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
    }
    
    public static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }

    public static var dataDirectory: URL {
        
        #if os(OSX)
        return self.documentsDirectory
        #else
        return self.documentsDirectory.appendingPathComponent(
            "Data",
            isDirectory: true)
        #endif
    }
    
    func setup(_ completion: @escaping () -> Void) {
        loadPersistentStore {
            completion()
        }
    }
    
    private func loadPersistentStore(completion: @escaping () -> Void) {
//        migrateStoreIfNeeded {
            self.persistentContainer.loadPersistentStores { description, error in
                guard error == nil else {
                    fatalError("was unable to load store \(error!)")
                }
                completion()
            }
//        }
    }
    
    private func migrateStoreIfNeeded(completion: @escaping () -> Void) {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            fatalError("persistentContainer was not set up properly")
        }
        
        if migrationEngine.requiresMigration(at: storeURL, toVersion: CoreDataMigrationVersion.current) {
            DispatchQueue.global(qos: .userInitiated).async {
                self.migrationEngine.migrateStore(at: storeURL, toVersion: CoreDataMigrationVersion.current)
                
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else {
            completion()
        }
    }
}
