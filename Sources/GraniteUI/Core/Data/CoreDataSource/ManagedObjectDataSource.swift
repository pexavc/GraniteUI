//
//  CoreDataManagedObject.swift
//
//
//  Created by 0xZala on 2/26/21.
//

import Foundation
import CoreData
#if os(iOS) || os(tvOS)
import UIKit
#endif

public protocol CoreDataManaged: AnyObject {
    associatedtype Model: NSManagedObject
    static func request() -> NSFetchRequest<Model>
    static var entityName: String { get }
}

public typealias CoreDataManagedObject = NSManagedObject & CoreDataManaged

#if os(iOS) || os(tvOS)
public class ManagedObjectDataSource<ManagedObject: CoreDataManagedObject> {
    public let controller: NSFetchedResultsController<ManagedObject>
    
    public var sortDescriptors: [NSSortDescriptor]? {
        get { controller.fetchRequest.sortDescriptors }
        set { controller.fetchRequest.sortDescriptors = newValue }
    }
    
    public var predicate: NSPredicate? {
        get { controller.fetchRequest.predicate }
        set { controller.fetchRequest.predicate = newValue }
    }

    public init(
        context: NSManagedObjectContext,
        sortDescriptors: [NSSortDescriptor]? = nil,
        sectionNameKeyPath: String? = nil,
        predicate: NSPredicate? = nil,
        cacheName: String? = nil
        ) {
        
        let request = NSFetchRequest<ManagedObject>(
            entityName: ManagedObject.entityName)
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        let controller = NSFetchedResultsController<ManagedObject>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: cacheName)
        
        self.controller = controller
    }
    
    public func register(
        tableView: UITableView,
        process: @escaping (UITableView, IndexPath, ManagedObject) -> UITableViewCell
    ) {
        box = .tableView(.init(
            controller: controller,
            tableView: tableView,
            source: self,
            processingFunction: process))
    }
    
    public func register(
        collectionView: UICollectionView,
        process: @escaping (UICollectionView, IndexPath, ManagedObject) -> UICollectionViewCell,
        processSupplementary: ((UICollectionView, String, IndexPath) -> UICollectionReusableView)? = nil,
        movingFunction: ((UICollectionView, IndexPath, IndexPath) -> ())? = nil
    ) {
        box = .collectionView(.init(
            controller: controller,
            collectionView: collectionView,
            source: self,
            processingFunction: process,
            processingSupplementaryFunction: processSupplementary,
            movingFunction: movingFunction))
    }
    
    public func performFetch() {
        try? controller.performFetch()
    }
    
    public subscript(indexPath: IndexPath) -> ManagedObject {
        get {
            controller.object(at: indexPath)
        }
    }
    
    public func object(at indexPath: IndexPath) -> ManagedObject {
        controller.object(at: indexPath)
    }
    
    private enum DataSourceBox {
        case none
        case tableView(TableViewBox)
        case collectionView(CollectionViewBox)
    }
    
    private var box: DataSourceBox = .none
    
    private class TableViewBox: NSObject,
        NSFetchedResultsControllerDelegate,
        UITableViewDataSource
    {
        let controller: NSFetchedResultsController<ManagedObject>
        
        weak var tableView: UITableView?
        weak var source: ManagedObjectDataSource<ManagedObject>?
        
        let processingFunction: (UITableView, IndexPath, ManagedObject) -> UITableViewCell
        
        init(
            controller: NSFetchedResultsController<ManagedObject>,
            tableView: UITableView,
            source: ManagedObjectDataSource<ManagedObject>,
            processingFunction: @escaping (UITableView, IndexPath, ManagedObject) -> UITableViewCell
        ) {
            self.controller = controller
            self.tableView = tableView
            self.source = source
            self.processingFunction = processingFunction
            super.init()
            controller.delegate = self
            tableView.dataSource = self
        }
        
        func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange sectionInfo: NSFetchedResultsSectionInfo,
            atSectionIndex sectionIndex: Int,
            for type: NSFetchedResultsChangeType
        ) {
            switch type {
            case .insert:
                tableView?.insertSections(
                    [sectionIndex], with: .fade)
            case .delete:
                tableView?.deleteSections(IndexSet(), with: .fade)
            case .move: break
            case .update:
                tableView?.reloadSections([sectionIndex], with: .fade)
            @unknown default: break
            }
        }
        
        func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange anObject: Any,
            at indexPath: IndexPath?,
            for type: NSFetchedResultsChangeType,
            newIndexPath: IndexPath?
        ) {
            switch type {
            case .insert:
                if let path = indexPath {
                    tableView?.insertRows(at: [path], with: .fade)
                }
            case .delete:
                if let path = indexPath {
                    tableView?.deleteRows(at: [path], with: .fade)
                }
            case .move:
                if
                    let path = indexPath,
                    let newPath = newIndexPath
                {
                    tableView?.moveRow(at: path, to: newPath)
                }
            case .update:
                if let path = indexPath {
                    tableView?.reloadRows(at: [path], with: .fade)
                }
            @unknown default: ()
            }
        }
        
        func controllerWillChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            tableView?.beginUpdates()
        }
        
        func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            tableView?.endUpdates()
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return controller.sections?.count ?? 0
        }
        
        func tableView(
            _ tableView: UITableView,
            numberOfRowsInSection section: Int
        ) -> Int {
            if let section = controller.sections?[section] {
                return section.numberOfObjects
            } else {
                return 0
            }
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            self.processingFunction(
                tableView,
                indexPath,
                self.controller.object(at: indexPath))
        }
    }
    
    private class CollectionViewBox: NSObject,
        NSFetchedResultsControllerDelegate,
        UICollectionViewDataSource
    {
        let controller: NSFetchedResultsController<ManagedObject>
        
        weak var collectionView: UICollectionView?
        weak var source: ManagedObjectDataSource<ManagedObject>?
        
        let processingFunction: (UICollectionView, IndexPath, ManagedObject) -> UICollectionViewCell
        let processingSupplementaryFunction: ((UICollectionView, String, IndexPath) -> UICollectionReusableView)?
        
        let movingFunction: ((UICollectionView, IndexPath, IndexPath) -> ())?
        
        init(
            controller: NSFetchedResultsController<ManagedObject>,
            collectionView: UICollectionView,
            source: ManagedObjectDataSource<ManagedObject>,
            processingFunction: @escaping (UICollectionView, IndexPath, ManagedObject) -> UICollectionViewCell,
            processingSupplementaryFunction: ((UICollectionView, String, IndexPath) -> UICollectionReusableView)?,
            movingFunction: ((UICollectionView, IndexPath, IndexPath) -> ())?
        ) {
            self.controller = controller
            self.collectionView = collectionView
            self.source = source
            self.processingFunction = processingFunction
            self.processingSupplementaryFunction = processingSupplementaryFunction
            self.movingFunction = movingFunction
            super.init()
            controller.delegate = self
            collectionView.dataSource = self
        }
        
        private var blockOperations: [BlockOperation] = []
        
        func controllerWillChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            blockOperations.removeAll(keepingCapacity: false)
        }
        
        func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange anObject: Any,
            at indexPath: IndexPath?,
            for type: NSFetchedResultsChangeType,
            newIndexPath: IndexPath?
        ) {
            guard
                let collectionView = self.collectionView
                else { return }
            let op: BlockOperation
            switch type {
            case .insert:
                guard let newIndexPath = newIndexPath else { return }
                op = BlockOperation { collectionView.insertItems(at: [newIndexPath]) }
            case .delete:
                guard let indexPath = indexPath else { return }
                op = BlockOperation { collectionView.deleteItems(at: [indexPath]) }
            case .move:
                guard
                    let indexPath = indexPath,
                    let newIndexPath = newIndexPath,
                    indexPath != newIndexPath
                    else { return }
                op = BlockOperation {
                    collectionView.deleteItems(at: [indexPath])
                    collectionView.insertItems(at: [newIndexPath])
                }
            case .update:
                guard let indexPath = indexPath else { return }
                op = BlockOperation { collectionView.reloadItems(at: [indexPath]) }
            @unknown default:
                op = BlockOperation {}
                break
            }
            
            blockOperations.append(op)
        }
        
        func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            guard
                let collectionView = self.collectionView
                else { return }
            
            collectionView.performBatchUpdates({
                self.blockOperations.forEach { $0.start() }
            }, completion: { finished in
                self.blockOperations.removeAll(keepingCapacity: false)
            })
        }
        
        func numberOfSections(
            in collectionView: UICollectionView
        ) -> Int {
            return controller.sections?.count ?? 0
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            numberOfItemsInSection section: Int
        ) -> Int {

            if let section = controller.sections?[section] {
                return section.numberOfObjects
            } else {
                return 0
            }
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            self.processingFunction(
                collectionView,
                indexPath,
                self.controller.object(at: indexPath))
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            viewForSupplementaryElementOfKind kind: String,
            at indexPath: IndexPath) -> UICollectionReusableView {
            
            guard processingSupplementaryFunction != nil else {
                return .init()
            }
            
            return self.processingSupplementaryFunction!(
                collectionView,
                kind,
                indexPath)
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            canMoveItemAt indexPath: IndexPath
        ) -> Bool {
            return movingFunction != nil
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            moveItemAt sourceIndexPath: IndexPath,
            to destinationIndexPath: IndexPath
        ) {
            movingFunction?(collectionView, sourceIndexPath, destinationIndexPath)
        }
    }
}
#endif
