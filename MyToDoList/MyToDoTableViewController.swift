//
//  MyToDoTableViewController.swift
//  MyToDoList
//
//  Created by Peterson Cemoin on 11/5/19.
//  Copyright © 2019 YourAreAwesome. All rights reserved.
//

import UIKit
import CoreData

class MyToDoTableViewController: UITableViewController {

    //use for textfield validation
    var taskName: UITextField!
    var invalidErrorMessage:String = "Please enter a valid value"
    var taskNames : [Task] = []
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    //use to know when we're editing. We'll edit whenever a cell is selected
    var isInEditMode : Bool = false
    //use to know index of selected row outside of our delegate method
    var selectedIndex:Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.taskNames = appDelegate.retrieveTasks()
        self.tableView.reloadData()
    }
    
    @IBAction func addItemToList(_ sender: Any) {
        displayForm(message: "")
    }
    
    func displayForm(message:String){
        
        //create alert
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        //create cancel button
        let cancelAction = UIAlertAction(title: "Cancel" , style: .cancel){ (action) -> Void in
            //we need to set
            self.isInEditMode = false
        }
        
        //create Next button
        let nextAction = UIAlertAction(title: "Next", style: .default) { (action) -> Void in
            self.validateInput(isNext: true)
        }
        
        //create Done button
        let doneAction = UIAlertAction(title: "Done", style: .default) { (action) -> Void in
            self.validateInput(isNext: false)
        }
        
        //create an update button. Will only display this button with cancel when a cell is being edited.
        let updateAction = UIAlertAction(title: "Update", style: .default) {(action) -> Void in
            self.validateInput(isNext: false)
        }
        
        if (self.isInEditMode){
            //edit tableview buttons
            alert.addAction(updateAction)
            
        }else{
            //add task to tableview buttons
            alert.addAction(nextAction)
            alert.addAction(doneAction)
        }
        alert.addAction(cancelAction)
        
        
        
        //create taskName textfield
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            if(self.isInEditMode){
                textField.text = self.taskNames[self.selectedIndex].name
            }else{
                textField.placeholder = "Type task name here..."
            }
            
            self.taskName = textField
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //validate input
    func validateInput(isNext:Bool){
        if((self.taskName.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)!){
            //if this code is run, that mean at least of the fields doesn't have value
            
            self.taskName.text = ""
            //display the appropriate error message
            let errorMessage = self.isInEditMode ? "" : self.invalidErrorMessage
            self.displayForm(message: errorMessage )
        }
        else{
            
            //edit task
            if(self.isInEditMode){
             updateTask(taskName: self.taskName.text!)
            }
            //add task
            else{
                
                let _task = Task(context: self.context)
                _task.name = self.taskName.text!
                _task.id = UUID().uuidString
                addTask(task: _task)
            }
            
            
            //if isNext is true, we know more input need to be entered, otherwise dismiss the popup
            if(isNext){
                displayForm(message: "")
            }
        }
    }
    
    //add task name to table
    func addTask(task:Task){
        
        //insert taskname in collection
        self.taskNames.append(task)
        
        //this index is needed since we're using zero-base index
        let index = self.taskNames.count - 1
        
        //index path informs the table view of which section and index to add the new value
        let indexPath = IndexPath(item: index, section: 0)
        
        //insert value in table view
        self.tableView?.insertRows(at: [indexPath], with: .automatic)
        self.appDelegate.saveContext()
    }
    
    //update task name in table
    func updateTask(taskName:String){
        //just update the collect, then refresh the tableview
        self.taskNames[self.selectedIndex].name = taskName
        
        do{
            //needed to fetch request
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
            //predicate to match task on id
            let predicate = NSPredicate(format: "id = %@", self.taskNames[self.selectedIndex].id!)
            //setting request predicate
            fetchRequest.predicate = predicate
            
            //look for task
            let foundTasks = try context.fetch(fetchRequest) as! [Task]
            //update found task
            foundTasks.first?.name = taskName
            
            //reload table
            self.tableView.reloadData()
            //save update
            try self.context.save()
            
        }catch{
          print("Something happen while trying to update a task")
        }
    }
    
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        //we'll only use one section
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //The number of rows displayed in the table
        return self.taskNames.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myToDoTask", for: indexPath)
        
        cell.textLabel?.text = self.taskNames[indexPath.row].name
         
        return cell
    }


    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let _task = self.taskNames[indexPath.row]
            let context = appDelegate.persistentContainer.viewContext;
            
            let taskFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
            let predicate = NSPredicate(format: "id = %@", _task.id!)
            taskFetchRequest.predicate = predicate
            
            do{
                let foundTaskts = try context.fetch(taskFetchRequest) as! [Task]
                context.delete(foundTaskts.first!)
                
                // delete the record from collection
                self.taskNames.remove(at: indexPath.row)
                
                //delete row from tableview
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                //refresh tableview
                tableView.reloadData()
                
                //saving delete in context
                try context.save()
                
            }catch{
                print("Something happened while trying to delete task...")
            }
            
            
        }
    }
    
    //edit cell when table is selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //we need to set isInEditMode
        self.isInEditMode = true
        self.selectedIndex = indexPath.row
        self.displayForm(message: "")
    }

}
