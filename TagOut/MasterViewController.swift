//
//  MasterViewController.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-07.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.

import UIKit

class MasterViewController: UITableViewController {

    var roomViewController: RoomViewController? = nil
    var objects = [Any]()
    
    let playerService = PlayerServiceManager()
    @IBOutlet var table: UITableView!
    var alertView: UIAlertController!;
    weak var roomCreationAction : UIAlertAction?

    var roomName: UITextField?
    var userName: String = "test";
    var creatorRoomIndex: Int!;
    var didUpdateRooms: Bool = false;
    
    var rooms: [[String: [String]]] = [] { //array of roomname: roompeople dictionary
        didSet {
            if didUpdateRooms == false { //prevent from making an infinite loop
                print("sending didUpdateRooms msg");
                playerService.send(rooms: rooms);
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerService.delegate = self;
        table.isUserInteractionEnabled = false; //turn off user interaction until table is fully loaded
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createRoom(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.roomViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? RoomViewController
        }
        
        //get rooms
        
        table.isUserInteractionEnabled = true;
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func createRoom(_ sender: Any) {
        let alert = UIAlertController(title: "Create Room", message: "", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField(configurationHandler: {(textField: UITextField) in
            textField.placeholder = "Enter Room Name Here"
            textField.addTarget(self, action: #selector(self.textChanged(_:)), for: .editingChanged)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (_) -> Void in
        })
        
        let action = UIAlertAction(title: "Create", style: UIAlertActionStyle.default, handler: { (_) -> Void in
            let textfield = alert.textFields!.first!
            self.rooms.append([textfield.text!: [self.userName]]); //create room with the user
            self.creatorRoomIndex = self.rooms.count-1;
            self.performSegue(withIdentifier: "showRoom", sender: self)
        })
        
        alert.addAction(cancel)
        alert.addAction(action)
        
        self.roomCreationAction = action
        action.isEnabled = false
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func textChanged(_ sender:Any) {
        let text = (sender as! UITextField).text
        
        for room in (self.rooms) {
            if room[text!] != nil { //room exists
                self.roomCreationAction?.isEnabled = false; //keep as false
                return;
            }
        }
        
        self.roomCreationAction?.isEnabled = (text! != "") //now need to only check if nothing entered
    }
    
    func printAllRooms() {
        for room in rooms {
            let roomNameTxt = ([String] (room.keys))[0];
            print("Room is \(roomNameTxt)");
        }
    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRoom" { //segue for room selector
            let controller = (segue.destination as! UINavigationController).topViewController as! RoomViewController
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let currRoom = rooms[indexPath.row];
                let roomNameTxt = ([String] (currRoom.keys))[0];
                var personArr = rooms[indexPath.row][roomNameTxt];
                personArr?.append(userName);
                rooms[indexPath.row][roomNameTxt] = personArr;
                controller.players = rooms[indexPath.row][roomNameTxt]
            }
            else { //segue for room creator
                let currRoom = rooms[creatorRoomIndex];
                let roomNameTxt = ([String] (currRoom.keys))[0];
                controller.roomName = roomNameTxt; //currRoom
                controller.players = rooms[creatorRoomIndex][roomNameTxt]
            }
        }
    }

    // MARK: - Table View
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("index path is \(indexPath.row)");
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let currRoom = ([String] (rooms[indexPath.row].keys))[0]
        cell.textLabel!.text = currRoom;
        return cell
    }
}

extension MasterViewController : PlayerServiceManagerDelegate {
    
    func connectedDevicesChanged(manager: PlayerServiceManager, connectedDevices: [String]) {
        DispatchQueue.main.async {
            print("Connections: \(connectedDevices)"); //update here
            
            //self.table.reloadData();
        }
    }
    
    func roomsChanged(manager: PlayerServiceManager, rooms: [[String: [String]]]) {
        DispatchQueue.main.async {
            print("updating rooms");
            self.didUpdateRooms = true;
            self.rooms = rooms;
            self.didUpdateRooms = false;
            self.table.reloadData();
        }
    }
    //OperationQueue.main.addOperation {
    /*switch colorString {
     case "red":
     self.change(color: .red)
     case "yellow":
     self.change(color: .yellow)
     default:
     NSLog("%@", "Unknown color value received: \(colorString)")
     }*/

}
