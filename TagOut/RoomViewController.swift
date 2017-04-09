//
//  DetailViewController.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-07.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//

import UIKit

class RoomViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var table: UITableView!
    var gameAlert: UIAlertController!;
    var isAdmin: Bool = false;
    var countdownTime: Int = 5;
    var timer: Timer = Timer();
    static var instance: RoomViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        RoomViewController.instance = self
        table.delegate = self
        table.dataSource = self
        table.isUserInteractionEnabled = false;
        if MasterViewController.instance?.userName == players?[0] { //admin notification for room creator
            adminNotification();
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if !self.isMovingFromParentViewController {
            MasterViewController.instance?.personDidLeaveRoom(roomName: roomName!);
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players!.count;
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel!.text = players![indexPath.row]
        return cell
    }

    
    var roomName: String? {
        didSet {
            self.title = "Room: \(roomName!)";
        }
    }
    
    func adminNotification() {
        let alert = UIAlertController(title: "You are now admin!", message: "", preferredStyle: UIAlertControllerStyle.alert)
        let cancel = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: { (_) -> Void in
        })
        
        alert.addAction(cancel);
        self.present(alert, animated: true, completion: nil)
        isAdmin = true;
        let addButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(playGame(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if (players?.count)! < 2 { //if less than two players, disable the play button
            self.navigationItem.rightBarButtonItem?.isEnabled = false;
        }
    }
    
    func playGame(_ sender: Any) {
        if isAdmin {
            MasterViewController.instance?.notifyGameBegin(roomName: roomName!);
        }
        //wait
        gameAlert = UIAlertController(title: "Game Play", message: "Game begins in \(countdownTime)", preferredStyle: UIAlertControllerStyle.alert)
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime(_:)), userInfo: nil, repeats: true)
        
        self.present(gameAlert, animated: true, completion: nil)
    }
    
    @objc func updateTime(_ sender: Any) {
        countdownTime -= 1;
        gameAlert.message = "Game begins in \(countdownTime)";
        if (countdownTime == 0) {
            print("game begins");
            timer.invalidate();
        }
    }
    
    var players: [String]? {
        didSet {
            for i in players! {
                print("\(i), ")
            }
            if (players?.count)! > 1 && isAdmin { //make button editable for admins
                self.navigationItem.rightBarButtonItem?.isEnabled = true;
            }
            print("MasterViewController.instance?.userName == players?[0] is \(MasterViewController.instance?.userName == players?[0])")
            print("isViewLoaded is \(isViewLoaded)")
            print("isAdmin is \(isAdmin)")
            if MasterViewController.instance?.userName == players?[0] && isViewLoaded && !isAdmin { //make first person in queue admin
                adminNotification();
            }
            if table != nil {
                DispatchQueue.main.async {
                    self.table.reloadData();
                }
            }
        }
    }
}

