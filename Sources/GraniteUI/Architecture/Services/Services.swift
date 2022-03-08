import Foundation
import CoreData

public class Services {
    public static let shared: Services = .init()
    public init() {}
    
    public var coreData: CoreDataManager = {
        return CoreDataManager(name: "version0001")
    }()
    
    public var keychain: UserDataKeychain = {
        return .init()
    }()
    
    public var coreDataInstance: NSManagedObjectContext {
        return Thread.isMainThread ? coreData.main : coreData.background
    }
    
    public var localStorage: LocalStorage = {
        return .init()
    }()
}
