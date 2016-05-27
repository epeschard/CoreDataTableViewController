//
//  CoreDataTable.swift
//  CoreData1
//
//  Created by Eugène Peschard on 21/07/15.
//  Copyright © 2015 Gourmi.es. All rights reserved.
//

import UIKit
import CoreData
import GourmiesKit

class CoreDataTable: UITableViewController,
NSFetchedResultsControllerDelegate {
    
    var coreDataStack: CoreDataStack! {
        didSet {
            self.managedObjectContext = coreDataStack.managedObjectContext
        }
    }
    var managedObjectContext: NSManagedObjectContext!
    
    var cellID: String!
    var entityName: String!
    var sorters: [String: Bool]!
    var sortDescriptors: [NSSortDescriptor]?
    var preFetches: [String]?
    var sectionNameKeyPath: String? = nil
    var cacheName: String? = nil
    var textForEmptyLabel = "No data is available"
    
//    var detailViewController: DetailViewController? = nil
    
    var predicate: NSPredicate! /*{
        willSet {
            fetchedResultsController.fetchRequest.predicate = newValue
        }
    }*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.rightBarButtonItem = editButtonItem()
        
        performFetch()
        
//        tableView.backgroundColor = UIColor.blackColor()
//        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
//        tableView.indicatorStyle = .White
    }
    
    func handleEmptyTable() {
        //create a lable size to fit the Table View
        let messageLbl = UILabel(frame: CGRectMake(0, 0,
            tableView.bounds.size.width,
            tableView.bounds.size.height))
        
        //set the message
        messageLbl.text = textForEmptyLabel
        
//        messageLbl.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        messageLbl.font = UIFont.systemFontOfSize(19)
        messageLbl.textColor = UIColor.grayColor()
        
        // Attributed Text
//        messageLbl.attributedText =
        
        //center the text
        messageLbl.textAlignment = .Center
        //multiple lines
        messageLbl.numberOfLines = 0
        
        //auto size the text
        messageLbl.sizeToFit()
        
        //set back to label view
        tableView.backgroundView = messageLbl
        
        //no separator
        tableView.separatorStyle = .None
    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        guard let sections = self.fetchedResultsController.sections else {
            return 1
        }
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
//        return sectionInfo.numberOfObjects
        let rowCount = sectionInfo.numberOfObjects
        
        // When no data insert centered label
        if rowCount == 0 && fetchedResultsController.sections!.count == 1 {
            handleEmptyTable()
        } else {
            // Remove empty table label
            tableView.backgroundView = nil
            tableView.separatorStyle = .SingleLine
        }
        
        return rowCount
    }
    
    override func tableView(tableView: UITableView,
        titleForHeaderInSection section: Int) -> String? {
            guard let sections = self.fetchedResultsController.sections else {
                return nil
            }
            let sectionInfo = sections[section]
//            let sectionInfo = self.fetchedResultsController.sections?[section]
//                as NSFetchedResultsSectionInfo
            
            return sectionInfo.name
    }
    
    override func tableView(tableView: UITableView,
        sectionForSectionIndexTitle title: String,
        atIndex index: Int) -> Int {
            return self.fetchedResultsController.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return self.fetchedResultsController.sectionIndexTitles
    }
    
    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier(cellID,
                forIndexPath: indexPath) as UITableViewCell
            self.configureCell(cell, indexPath: indexPath)
            return cell
    }
    
    func configureCell(cell: UITableViewCell,
        indexPath: NSIndexPath) {
            print("CoreDataTable - configureCell:atIndexPath not overridden")
//            let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
//            cell.textLabel!.text = object.valueForKey("timeStamp")!.description
    }
    
    override func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
            if editingStyle == .Delete {
                let object = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
                //            location.removePhotoFile()
                managedObjectContext.deleteObject(object as NSManagedObject)
                
                do {
                    try managedObjectContext.save()
                } catch let error as NSError {
                    print("ERROR saving \(error.localizedDescription)")
//                    fatalCoreDataError(error)
                }
            }
    }
    
    // MARK: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest()
        
        let entity = NSEntityDescription.entityForName(self.entityName!,
            inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entity
        
        fetchRequest.sortDescriptors = self.sortDescriptors
        
        fetchRequest.fetchBatchSize = 20
        
        fetchRequest.predicate = self.predicate
//        print("CoreDataTable.predicate: \(self.predicate)")
        
        fetchRequest.relationshipKeyPathsForPrefetching = self.preFetches
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: self.sectionNameKeyPath,
            cacheName: self.cacheName)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("ERROR saving \(error.localizedDescription)")
//            fatalCoreDataError(error)
        }
//        tableView.reloadData()
    }
    
    func updateFetchRequestWithPredicate(predicate: NSPredicate) {
        let fetchRequest = NSFetchRequest()
        
        let entity = NSEntityDescription.entityForName(self.entityName!,
            inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entity
        
        fetchRequest.sortDescriptors = self.sortDescriptors
        
        fetchRequest.fetchBatchSize = 20
        
        fetchRequest.predicate = predicate
        print("Updated FRC with predicate: \(fetchRequest.predicate)")
        
        fetchRequest.relationshipKeyPathsForPrefetching = self.preFetches
        
        let newFetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: self.sectionNameKeyPath,
            cacheName: self.cacheName)
        
        fetchedResultsController = newFetchedResultsController
        fetchedResultsController.delegate = self
    }
    
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // In the simplest, most efficient, case, reload the table view.
        self.tableView.reloadData()
    }
    
    
    // MARK: - iCloud Core Data
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // iCloud Core Data
        coreDataStack.updateContextWithUbiquitousContentUpdates = true
        persistentStoreCoordinatorChangesObserver = NSNotificationCenter.defaultCenter()
    }
    
    var persistentStoreCoordinatorChangesObserver:
        NSNotificationCenter? {
        didSet {
            oldValue?.removeObserver(self,
                name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
                object: coreDataStack.persistentStoreCoordinator)
            oldValue?.removeObserver(self,
                name: NSPersistentStoreCoordinatorStoresWillChangeNotification,
                object: coreDataStack.persistentStoreCoordinator)
            
            persistentStoreCoordinatorChangesObserver?.addObserver(self,
                selector: #selector(CoreDataTable.persistentStoreCoordinatorDidChangeStores(_:)),
                name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
                object: coreDataStack.persistentStoreCoordinator)
            persistentStoreCoordinatorChangesObserver?.addObserver(self,
                                                                   selector: #selector(CoreDataStack.persistentStoreCoordinatorWillChangeStores(_:)),
                name:NSPersistentStoreCoordinatorStoresWillChangeNotification,
                object: coreDataStack.persistentStoreCoordinator)
        }
    }
    
    func persistentStoreCoordinatorDidChangeStores(notification: NSNotification) {
        //        var error: NSErrorPointer = nil
        if coreDataStack.managedObjectContext.hasChanges {
            do {
                try coreDataStack.managedObjectContext.save()
            } catch let error as NSError {
                print("CoreDataTable - ERROR coreDataStack.managedObjectContext.save()\n")
                print(" Error: \(error.localizedDescription)")
                abort()
            }
//            if coreDataStack.managedObjectContext.save() == false {
//                print("Error saving: \(error)")
//            }
        }
        coreDataStack.managedObjectContext.reset()
    }
    
}
