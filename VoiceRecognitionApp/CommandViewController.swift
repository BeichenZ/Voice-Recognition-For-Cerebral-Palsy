//
//  CommandViewController.swift
//  VoiceRecognitionApp
//
//  Created by BC on 2017-02-24.
//  Copyright © 2017 BC. All rights reserved.
//

import UIKit
import os.log


class CommandViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    var defaultCommandList=[Command]()

    @IBOutlet weak var commandListTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let savedCommands = loadCommands() {
            defaultCommandList += savedCommands
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for:segue,sender:sender)
        
        guard let commandDetailVC=segue.destination as? CommandDetailViewController else{fatalError("unidentified destination VC")}
        
        switch (segue.identifier ?? "")
        {
            case "editExistingCommandSegue":
                commandDetailVC.callingType=1
                
                
                //sender is the cell being selected
                guard let selectedCell=sender as? CommandTableViewCell else{fatalError("unidentified Segue sender")}
                
                guard let selectedCellIndexPath=commandListTable.indexPath(for:selectedCell) else {
            fatalError("The selected cell is not being displayed by the table")}
            
                commandDetailVC.command = defaultCommandList[selectedCellIndexPath.row]

            
            case "addNewCommandSegue":
                os_log("Adding a new command.", log: OSLog.default, type: .debug)
                commandDetailVC.callingType=2
            
            default:
                fatalError("Unexpected segue identifier name: \(segue.identifier)")
            
        }
    }
    
    
    
    
    //MARK:Table View Delegate Functions
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return defaultCommandList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "commandListCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CommandTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        // Fetches the appropriate command for the data source layout.
        let currentCommand = defaultCommandList[indexPath.row]
        cell.commandNameLabel.text=currentCommand.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == .delete{
            defaultCommandList.remove(at: indexPath.row)
            saveCommands()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    //MARK:Action
    @IBAction func unwindFromCommandDetail(sender:UIStoryboardSegue)
    {
        guard let sourceVC=sender.source as? CommandDetailViewController else{fatalError("was expecting CommandDetailViewController")}
        
        //store the data into source's data storage
        
        let changedCommand=sourceVC.command
        switch sourceVC.callingType
        {
            case 1://From an edit action
                if let selectedIndexPath=commandListTable.indexPathForSelectedRow
            {
                defaultCommandList[selectedIndexPath.row]=changedCommand!
                commandListTable.reloadRows(at:[selectedIndexPath],with:.none)
            }
            case 2://From a add-new command
                let newIndexPath=IndexPath(row:defaultCommandList.count,section:0)
                defaultCommandList.append(changedCommand!)
                commandListTable.insertRows(at:[newIndexPath],with:.automatic)
        default:
            fatalError("unexpected commandDetail callingtype: \(sourceVC.callingType)")
        }
        //save the commands
        saveCommands()
    }
    
    private func saveCommands(){
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(defaultCommandList, toFile:Command.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Commands successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save meals...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadCommands() -> [Command]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Command.ArchiveURL.path) as? [Command]
    }
}
