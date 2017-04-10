//
//  GameViewController.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-09.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//

import UIKit
import CoreLocation

class GameViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var shootAgain: UILabel!
    @IBOutlet weak var tagLivesLabel: UILabel!
    @IBOutlet weak var taggedLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    var playersSender: Bool = false;
    var playerLivesSender: Bool = false;
    var locValue:CLLocationCoordinate2D? = nil;
    var heading: CLLocationDirection? = nil;
    var timer: Timer = Timer();
    let countdownConst: Int = 6;
    var countdownTime: Int = -1;
    
    var players: [String] = [] { //players who are in game
        didSet {
            if playersSender {
                //send notification to all players
            }
            table.reloadData();
        }
    }
    
    var playerLives: [String : Int] = [:] {
        didSet {
            //sort players by lives, highest to lowest, then
            if playerLivesSender {
                //send notification to all players
            }
            for i in 0..<players.count { //remove player lives
                if playerLives[players[i]] == 0 {
                    players.remove(at: i);
                }
            }
            table.reloadData();
        }
    }
    
    @IBAction func tagAction(_ sender: Any) {
        tagButton.isEnabled = false;
        startCountDown()
        //fetch location data from other people
        //for location data in locationDataArray received
        //see if anything intersects
    }
    
    func startCountDown() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime(_:)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTime(_ sender: Any) {
        countdownTime -= 1;
        shootAgain.text = "Shoot again in \(countdownTime)"
        if (countdownTime == 0) {
            timer.invalidate();
            countdownTime = countdownConst;
            tagButton.isEnabled = true;
            shootAgain.text = "Shoot again in ..."
        }
    }
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        players = (RoomViewController.instance?.players)!;
        
        for player in players { //initialize all players with 5 lives
            playerLives[player] = 5;
        }
        
        countdownTime = countdownConst;
        
        locationManager.delegate = self
        
        // Ask for Authorisation from the User. //ask in MasterViewController
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        if (CLLocationManager.headingAvailable()) {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
        }
    }
    
    func gameTimer() {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        print(heading.magneticHeading)
        self.heading = heading.magneticHeading;
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //update location if location has changes
        if (locValue?.latitude != manager.location?.coordinate.latitude && locValue?.longitude != manager.location?.coordinate.longitude) {
            locValue = manager.location!.coordinate
            print("locations = \((locValue?.latitude)!) \((locValue?.longitude)!)")
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count;
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel!.text = "\(indexPath.row + 1). \(players[indexPath.row]): \(playerLives[players[indexPath.row]]!) Lives Remaining"
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
