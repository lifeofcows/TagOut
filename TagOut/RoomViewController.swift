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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.delegate = self
        table.dataSource = self
        table.isUserInteractionEnabled = false;
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
    
    var players: [String]? {
        didSet {
            for i in players! {
                print("\(i), ")
            }
            if table != nil {
                DispatchQueue.main.async {
                    self.table.reloadData();
                }
            }
        }
    }
}

