//
//  MasterViewController.swift
//  NotesSaving
//
//  Created by Andres Garcia on 7/15/19.
//  Copyright © 2019 Andres Garcia. All rights reserved.
//

import UIKit
import CoreData

var n:Int = 0
var deletedNote:Int = 0
var prevIndexPath:IndexPath = [0, 0]
var increment:Bool = false
var selected = 0
var foundData = [SavedNotes]()
var deleteFoundData = [SavedNotes]()
var lastData = [SavedNotes]()
var amount:Int = 0
var savehit:Bool = false
var firstNote:Bool = false
var chosenCell:UITableViewCell?
var indexPathModifier:Int = 0

var managedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext



func reloadData(finding:Int32) -> SavedNotes{
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedNotes")
    
    do {
        if let results = try managedObjectContext.fetch(fetchRequest) as? [SavedNotes]{
            //print(results)
            //print("results count is \(results.count)")
            if(foundData.count > 0){
                if(lastData.count > 0){
                    lastData[0] = foundData[0]
                }
                else{
                    lastData.append(foundData[0])
                }
                foundData.remove(at: 0)
            }
            for thing in results{
                if thing.nval == finding{
                    foundData.append(thing)
                    break
                }
            }
            //print("lastData = \(lastData)")
                
        }
    } catch {
        fatalError("Error Reloading Data")
    }
        return foundData[0]
}

func reloadDataForDeletion(finding:Int32) -> SavedNotes{
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedNotes")
    
    do {
        if let results = try managedObjectContext.fetch(fetchRequest) as? [SavedNotes]{
            //print(results)
            //print("results count is \(results.count)")
            if(deleteFoundData.count > 0){
                
                deleteFoundData.remove(at: 0)
            }
            for thing in results{
                if thing.nval == finding{
                    deleteFoundData.append(thing)
                    break
                }
            }
            //print("lastData = \(lastData)")
                
        }
    } catch {
        fatalError("Error Reloading Data")
    }
        return deleteFoundData[0]
}

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    
    func saveData(){
        do{
            print("save successful")
            try managedObjectContext.save()
        } catch {
            print("failed to save")
        }
    }
    
    
    func retrieveCount() -> Int{
        //print("n started")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SavedNotes")
        
        do {
            //print("in do")
            if let results = try managedObjectContext.fetch(fetchRequest) as? [SavedNotes]{
                if results.count > 0{
                    amount = results.count
                }
            }
        } catch {
            fatalError("Error Reloading Data")
        }
        return amount
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //print("MASTER")
        self.title = "Backpedal"
        /*
        let cnote = reloadData(finding: Int32(1))
        print(cnote.name, cnote.content)*/
        navigationItem.leftBarButtonItem = editButtonItem
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        //let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: prevIndexPath)
        if n > 0{
            let cell = tableView.cellForRow(at: prevIndexPath)!
            if UIDevice.current.userInterfaceIdiom == .pad{
            }else{
                renameCell(cell)
            }
            saveData()
        }
        
        if(retrieveCount()<1){
            firstNote = true
            insertNewObject(self)
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //print("viewWillDisappear")
    }

    @objc
    func insertNewObject(_ sender: Any) {
        increment = true
        indexPathModifier += 1
        let context = self.fetchedResultsController.managedObjectContext
        let newEvent = Event(context: context)
        // If appropriate, configure the new managed object.
        newEvent.timestamp = Date()
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        //print("newObjCreated")
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
            let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    /*override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionName:String = "Backpedal"
        
        return sectionName
    }*/

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let event = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withEvent: event)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        chosenCell = tableView.cellForRow(at: prevIndexPath)
        
        //print(chosenCell)
        selected = (n - indexPath.row)
        prevIndexPath = tableView.indexPathForSelectedRow!
        //print("selected \(selected)")
        reloadData(finding: Int32(selected))
        
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            context.delete(fetchedResultsController.object(at: indexPath))
                
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func configureCell(_ cell: UITableViewCell, withEvent event: Event) {
        
        if (increment){
            n+=1
            let defaults = UserDefaults.standard
            //print("increm")
            defaults.set(defaults.integer(forKey: "totalNumEver") + 1, forKey: "totalNumEver")
            if(defaults.integer(forKey: "totalNumEver") > 1){
                firstNote = false
            }
            guard let entity = NSEntityDescription.entity(forEntityName: "SavedNotes", in: managedObjectContext) else {fatalError("Could not find entity description!")}
            let note = SavedNotes(entity: entity, insertInto: managedObjectContext)
            
            if(firstNote){
                note.name = "Tutorial"
                note.content = "Welcome to Backpedal! An app designed to help hearing impaired students and professionals note-take.\n\nEssentially, Backpedal is a notes and audio recording app merged into one.\n\nOne special feature is the 'alerts' system. If you click on the ! button (found on bar over your keyboard) while recording, Backpedal will record a timestamp.\n\nOnce you finish the recording, you can easily cycle through timestamps using the left and right arrow buttons. So, if you ever miss anything during a lecture, video, or anything else, hit the alert button and be stress-free!\n\nFinally, feel free to export your notes and audio files to Google Drive, or any other service, as soon as your done.\n\nI hope you enjoy your Backpedal experience!"
                note.nval = Int32(n)
                note.end_url = "\(String(defaults.integer(forKey: "totalNumEver")))AudioFile.m4a"
                cell.textLabel!.text = note.name
            }
            else{
                note.name = "Note \(defaults.integer(forKey: "totalNumEver"))"
                note.content = ""
                note.nval = Int32(n)
                note.end_url = "\(String(defaults.integer(forKey: "totalNumEver")))AudioFile.m4a"
                cell.textLabel!.text = note.name
            }
            //print("configuring cell")
            //print("n= \(n)")
            increment = false
            
            
            //print(cell.textLabel!.text!)
        }
        else if(firstNote == false){
            //print("else if")
            let prev = retrieveCount()
            //print("prev \(prev)")
            //print("n \(n)")
            n+=1
            print(Int32(prev - (n - 1)))
            
            let cnote = reloadData(finding: Int32(prev - (n - 1)))
            cell.textLabel?.text = cnote.name
            
            //renameCell(cell)
            
        }
    }
    
    /*func returnCell(_ cell: UITableViewCell) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: prevIndexPath)
        return cell
    }*/
    
    func renameCell(_ cell: UITableViewCell){
        let cnote = reloadData(finding: Int32(selected))
        cell.textLabel?.text = cnote.name
    }

    
    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Event> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
    
    var _fetchedResultsController: NSFetchedResultsController<Event>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                //print(chosenCell)
                tableView.insertRows(at: [newIndexPath!], with: .fade)
                print("\n\n\n")
                print(chosenCell)
            case .delete:
                //print("deleting = true")
                if(n - indexPath!.row == selected){
                    foundData.remove(at:0)
                    let nc = NotificationCenter.default
                    nc.post(name: deleteNotification, object: nil)
                }
                tableView.deleteRows(at: [indexPath!], with: .fade)
                increment = false
                deletedNote = (n - indexPath!.row)
                //print("deletedNote = \(deletedNote)")
                let dnote = reloadDataForDeletion(finding: Int32(deletedNote))
                print(dnote)
                managedObjectContext.delete(dnote)
                //print("n before -1 = \(n)")
                if deletedNote != n{
                    for num in deletedNote+1...n{
                        let cdnote = reloadDataForDeletion(finding: Int32(num))
                        print(cdnote)
                        cdnote.nval -= 1
                    }
                }
                //foundData.remove(at:0)
                n -= 1
                
                saveData()
                //print("deleting data")
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Event)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Event)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         tableView.reloadData()
     }
     */

}

