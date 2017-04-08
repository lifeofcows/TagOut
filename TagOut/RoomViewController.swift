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
        table.isUserInteractionEnabled = false;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players!.count;
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
            //print("players in \(roomName!) are now: ");
            for i in players! {
                print("\(i), ")
            }
        }
    }
    
    var roomIndex: Int? { //if room index shifts in dictionary
        didSet {
            
        }
    }
}

