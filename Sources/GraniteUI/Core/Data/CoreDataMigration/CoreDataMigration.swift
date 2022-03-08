//
//  CoreDataMigrationEngine.swift
//
//
//  Created by 0xZala on 2/26/21.
//

import Foundation
import CoreData
 
public protocol CoreDataMigration {
    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMigrationVersion) -> Bool
    func migrateStore(at storeURL: URL, toVersion version: CoreDataMigrationVersion)
}

public class CoreDataMigrationEngine: CoreDataMigration {
    
    public init() {}
    
    public func requiresMigration(
        at storeURL: URL,
        toVersion version: CoreDataMigrationVersion
    ) -> Bool {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            return false
        }
        
        return (CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata) != version)
    }
    
    public func migrateStore(
        at storeURL: URL,
        toVersion version: CoreDataMigrationVersion
    ) {
        forceWALCheckpointingForStore(at: storeURL)
        
        var currentURL = storeURL
        let migrationSteps = self.migrationStepsForStore(
            at: storeURL, toVersion: version)
        
        for migrationStep in migrationSteps {
            let manager = NSMigrationManager(
                sourceModel: migrationStep.sourceModel,
                destinationModel: migrationStep.destinationModel)
            let destinationURL = URL(
                fileURLWithPath: NSTemporaryDirectory(),
                isDirectory: true)
                .appendingPathComponent(UUID().uuidString)
            
            do {
                try manager.migrateStore(
                    from: currentURL,
                    sourceType: NSSQLiteStoreType,
                    options: nil,
                    with: migrationStep.mappingModel,
                    toDestinationURL: destinationURL,
                    destinationType: NSSQLiteStoreType,
                    destinationOptions: nil)
            } catch let error {
                fatalError("failed attempting to migrate from \(migrationStep.sourceModel) to \(migrationStep.destinationModel), error: \(error)")
            }
            
            if currentURL != storeURL {
                NSPersistentStoreCoordinator.destroyStore(at: currentURL)
            }
            
            currentURL = destinationURL
        }
        
        NSPersistentStoreCoordinator.replaceStore(
            at: storeURL,
            withStoreAt: currentURL)
        
        if (currentURL != storeURL) {
            NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
    }
    
    private func migrationStepsForStore(
        at storeURL: URL,
        toVersion destinationVersion: CoreDataMigrationVersion
    ) -> [CoreDataMigrationStep] {
        guard
            let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL),
            let sourceVersion = CoreDataMigrationVersion
                .compatibleVersionForStoreMetadata(metadata)
            else { fatalError("unknown store version at URL \(storeURL)") }
        
        return migrationSteps(
            fromSourceVersion: sourceVersion,
            toDestinationVersion: destinationVersion)
    }
    
    private func migrationSteps(
        fromSourceVersion sourceVersion: CoreDataMigrationVersion,
        toDestinationVersion destinationVersion: CoreDataMigrationVersion
    ) -> [CoreDataMigrationStep] {
        var sourceVersion = sourceVersion
        var migrationSteps = [CoreDataMigrationStep]()
        
        while
            sourceVersion != destinationVersion,
            let nextVersion = sourceVersion.nextVersion()
        {
            let migrationStep = CoreDataMigrationStep(
                sourceVersion: sourceVersion,
                destinationVersion: nextVersion)
            migrationSteps.append(migrationStep)
            
            sourceVersion = nextVersion
        }
        
        return migrationSteps
    }
    
    func forceWALCheckpointingForStore(
        at storeURL: URL
    ) {
        guard
            let metadata = NSPersistentStoreCoordinator.metadata(
                at: storeURL),
            let currentModel = NSManagedObjectModel
                .compatibleModelForStoreMetadata(metadata)
            else { return }
        
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(
                managedObjectModel: currentModel)
            
            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = persistentStoreCoordinator.addPersistentStore(
                at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
        } catch let error {
            fatalError("failed to force WAL checkpointing, error: \(error)")
        }
    }
}

private extension CoreDataMigrationVersion {
    
    static func compatibleVersionForStoreMetadata(_ metadata: [String : Any]) -> CoreDataMigrationVersion? {
        let compatibleVersion = CoreDataMigrationVersion.allCases.first {
            let model = NSManagedObjectModel.managedObjectModel(forResource: $0.rawValue)
            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }
        
        return compatibleVersion
    }
}

public enum CoreDataMigrationVersion: String, CaseIterable {
    case version1
    
    static var current: CoreDataMigrationVersion {
        guard let latest = allCases.last else {
            fatalError("no model versions found")
        }
        return latest
    }
    
    func nextVersion() -> CoreDataMigrationVersion? {
        switch self {
        case .version1:
            return nil
        }
    }
}

struct CoreDataMigrationStep {
    
    let sourceModel: NSManagedObjectModel
    let destinationModel: NSManagedObjectModel
    let mappingModel: NSMappingModel
    
    init(
        sourceVersion: CoreDataMigrationVersion,
        destinationVersion: CoreDataMigrationVersion
    ) {
        let sourceModel = NSManagedObjectModel.managedObjectModel(
            forResource: sourceVersion.rawValue)
        let destinationModel = NSManagedObjectModel.managedObjectModel(
            forResource: destinationVersion.rawValue)
        
        guard
            let mappingModel = CoreDataMigrationStep.mappingModel(
                fromSourceModel: sourceModel,
                toDestinationModel: destinationModel)
            else { fatalError("Expected modal mapping not present") }
        
        self.sourceModel = sourceModel
        self.destinationModel = destinationModel
        self.mappingModel = mappingModel
    }
    
    private static func mappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) -> NSMappingModel? {
        guard
            let customMapping = customMappingModel(
                fromSourceModel: sourceModel,
                toDestinationModel: destinationModel)
            else {
                return inferredMappingModel(
                    fromSourceModel:sourceModel,
                    toDestinationModel: destinationModel)
        }
        
        return customMapping
    }
    
    private static func inferredMappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) -> NSMappingModel? {
        return try? NSMappingModel.inferredMappingModel(
            forSourceModel: sourceModel,
            destinationModel: destinationModel)
    }
    
    private static func customMappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) -> NSMappingModel? {
        return NSMappingModel(
            from: [Bundle.main],
            forSourceModel: sourceModel,
            destinationModel: destinationModel)
    }
}
