//
//  NSManagedObjectModel.swift
//
//
//  Created by 0xZala on 2/26/21.
//

import Foundation
import CoreData

extension NSManagedObjectModel {
    static func compatibleModelForStoreMetadata(_ metadata: [String : Any]) -> NSManagedObjectModel? {
        let mainBundle = Bundle.main
        return NSManagedObjectModel.mergedModel(from: [mainBundle], forStoreMetadata: metadata)
    }
    
    static func managedObjectModel(forResource resource: String) -> NSManagedObjectModel {
           let mainBundle = Bundle.main
           let subdirectory = "CoreDataModel.momd"
           
           var omoURL: URL?
           if #available(iOS 11, *) {
               omoURL = mainBundle.url(forResource: resource, withExtension: "omo", subdirectory: subdirectory)
           }
           let momURL = mainBundle.url(forResource: resource, withExtension: "mom", subdirectory: subdirectory)
           
           guard let url = omoURL ?? momURL else {
               fatalError("unable to find model in bundle")
           }
           
           guard let model = NSManagedObjectModel(contentsOf: url) else {
               fatalError("unable to load model in bundle 2")
           }
           
           return model
       }
}
