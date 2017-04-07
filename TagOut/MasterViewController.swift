//
//  MasterViewController.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-07.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//
//https://www.ioscreator.com/tutorials/editable-text-field-alert-controller-tutorial

import UIKit

class MasterViewController: UITableViewController {

    var roomViewController: RoomViewController? = nil
    var objects = [Any]()
    
    @IBOutlet var table: UITableView!
    var alertView: UIAlertController!;
    var roomName: UITextField?
    var rooms: [String] = [String]()
    //var roomNameEntryTextfield: UITextField?
    //var passwordTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createRoom(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.roomViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? RoomViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func createRoom(_ sender: Any) {
        alertView = UIAlertController(title: "Create Room", message: "", preferredStyle: UIAlertControllerStyle.alert);
        
        let createAction = UIAlertAction(
        title: "Create", style: UIAlertActionStyle.default) {
            (action) -> Void in
            if (!self.rooms.contains((self.roomName?.text)!)) {
                self.rooms.append((self.roomName?.text)!);
                //send everyone the updated rooms
                //self.table.reloadData();
                self.performSegue(withIdentifier: "Room", sender: self)
            }
            else {
                print("room already exists with this name");
            }
        }
        
        alertView.addTextField {
            (txtRoomName) -> Void in
            self.roomName = txtRoomName
            self.roomName!.placeholder = "Enter Room Name Here"
        }
        
        alertView.addAction(createAction)
        self.present(alertView!, animated: true, completion: nil)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Room" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let currRoom = rooms[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! RoomViewController
                controller.detailItem = currRoom
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let currRoom = rooms[indexPath.row]
        cell.textLabel!.text = currRoom.description
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

