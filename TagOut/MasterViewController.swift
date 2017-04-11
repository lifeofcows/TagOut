//
//  MasterViewController.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-07.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.

import UIKit
import CoreLocation

class MasterViewController: UITableViewController {
    
    static var instance: MasterViewController!;
    var roomViewController: RoomViewController? = nil
    var objects = [Any]()
    
    var playerService: PlayerServiceManager! = nil;
    @IBOutlet var table: UITableView!
    weak var roomCreationAction : UIAlertAction?
    
    var roomName: UITextField?
    var userName: String!;
    var creatorRoomIndex: Int!;
    var didUpdateRooms: Bool = false;
    var didGetRooms: Bool = false;
    var currRoomName: String?;
    var controller: RoomViewController? = nil;
    
    var rooms: [[String: [String]]] = [] { //array of roomname: roompeople dictionary
        didSet {
            if didUpdateRooms == false { //prevent from making an infinite loop
                print("sending didUpdateRooms msg");
                playerService?.send(obj: rooms, peerStr: "", type: "UPDATE_ROOMS");
            }
            if (!didGetRooms) { //wait until rooms are loaded (set by another peer) then turn on userInteraction
                didGetRooms = true;
                table.isUserInteractionEnabled = true;
            }
            updateRoomPlayers();
        }
    }
    
    func updateRoomPlayers() { //function updates room
        if currRoomName != nil {
            for i in 0..<rooms.count {
                if rooms[i][currRoomName!] != nil {
                    controller?.players = rooms[i][currRoomName!];
                    return;
                }
            }
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        MasterViewController.instance = self;
        table.isUserInteractionEnabled = false; //turn off user interaction until table is fully loaded
        userName = randomString(length: 6);
        playerService = PlayerServiceManager(name: userName!) //init player service with username
        playerService.delegate = self;
        print("userName is \(userName!)")
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createRoom(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        self.navigationItem.rightBarButtonItem?.isEnabled = true;
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.roomViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? RoomViewController
        }
        self.navigationItem.hidesBackButton = true
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
            self.currRoomName = textfield.text!;
            self.rooms.append([self.currRoomName!: [self.userName]]); //create room with the user
            self.table.reloadData();
            self.creatorRoomIndex = self.rooms.count - 1;
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
    
    func notifyGameBegin() { //function notifies all peers in the room that the game is beginning, including the admin
        for room in rooms {
            if let playerArray = room[currRoomName!] {
                for player in playerArray {
                    playerService.send(obj: true, peerStr: player, type: "GAME_BEGIN");
                }
                return;
            }
        }
    }
    
    func sendToAllExceptUser(obj: Any, type: String) {
        for room in rooms {
            if let playerArray = room[currRoomName!] {
                for player in playerArray {
                    if player != userName {
                        playerService.send(obj: obj, peerStr: player, type: type); //get coordinates to everyone in room except current user
                    }
                }
            }
        }
    }
    
    func getCoordinates() {
        sendToAllExceptUser(obj: userName, type: "GET_COORDS");
    }
    
    func updatePlayerLives(playerLives: [String: Int]) {
        sendToAllExceptUser(obj: playerLives, type: "UPDATE_LIVES");
    }

    func printAllRooms() {
        for room in rooms {
            let roomNameTxt = ([String] (room.keys))[0];
            print("Room is \(roomNameTxt)");
        }
    }
    
    func personDidLeaveRoom(roomName: String) {
        currRoomName = nil;
        print("person leaving room");
        for i in 0..<rooms.count {
            if let room = rooms[i][roomName] {
                let index = room.index(of: userName!);
                var personArray = room
                personArray.remove(at: index!);
                if personArray.count == 0 { //remove room if no more players
                    rooms.remove(at: i);
                    table.reloadData();
                }
                else {
                    rooms[i][roomName] = personArray;
                }
                print("removed \(userName!) from room")
                return;
            }
        }
    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRoom" { //segue for room selector
            controller = (segue.destination as! UINavigationController).topViewController as! RoomViewController?
            controller?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller?.navigationItem.leftItemsSupplementBackButton = true

            if let indexPath = self.tableView.indexPathForSelectedRow {
                addToRoom(index: indexPath.row);
            }
            else { //segue for room creator
                let currRoom = rooms[creatorRoomIndex];
                let roomNameTxt = ([String] (currRoom.keys))[0];
                controller?.roomName = roomNameTxt; //currRoom
                controller?.players = rooms[creatorRoomIndex][roomNameTxt]
            }
        }
    }
    
    func addToRoom(index: Int) {
        print("adding \(userName!) to room")
        let currRoom = rooms[index];
        currRoomName = ([String] (currRoom.keys))[0];
        var personArr = rooms[index][currRoomName!];
        personArr?.append(userName);
        rooms[index][currRoomName!] = personArr;
        controller?.roomName = currRoomName; //currRoom
        controller?.players = rooms[index][currRoomName!]
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
    
    //gen random string
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}

extension MasterViewController : PlayerServiceManagerDelegate {
    
    func connectedDevicesChanged(connectedDevices: [String]) {
        DispatchQueue.main.async {
            print("Connections: \(connectedDevices)");
        }
    }
    
    func roomsChanged(rooms: [[String: [String]]]) {
        DispatchQueue.main.async {
            print("updating rooms");
            self.didUpdateRooms = true;
            self.rooms = rooms;
            self.didUpdateRooms = false;
            self.table.reloadData();
        }
    }
    
    func getRooms()->[[String: [String]]] {
        return rooms;
    }
    
    func gameBegin() {
        print("gameBegin gets called!")
        RoomViewController.instance?.countdownStart();
    }
}
