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
    //my coords: latitude37.785834000000001, longitude: -122.406417)
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var shootAgain: UILabel!
    @IBOutlet weak var tagLivesLabel: UILabel!
    @IBOutlet weak var taggedLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    var playersSender: Bool = false;
    var playerLivesSender: Bool = false;
    var heading: CLLocationDirection? = nil;
    let angleErrorMargin: Double = 4;
    var shotTimer: Timer = Timer();
    let shotCountdownConst: Int = 5;
    var shotCountdownTime: Int = -1;
    var gameEndTimer: Timer = Timer();
    var gameCountdownConst: Int = 120;
    var gameCountdownTime: Int = -1;
    let userName: String = (MasterViewController.instance?.userName!)!
    var lastPosition: CLLocationCoordinate2D!;
    
    static var instance: GameViewController?
    var needCoordsFrom: [String] = []
    var coordinates: [String: CLLocationCoordinate2D] = [:] { //name andcoordinates. array of players: inside, array of data (0th index = name, 1st is coords))
        didSet {
            let newPlayers = Set(coordinates.keys)
            let oldPlayers = Set(oldValue.keys);
            
            var checkPlayers = Array(newPlayers.symmetricDifference(oldPlayers)); //find players who need to be checked
            
            for player in checkPlayers {
                
            }
            
            
            /*
            let players = coordinates.keys;
            for i in players {
                print("player \(i)'s coordinates are: \(coordinates[i])");
            }
            
            var temp = needCoordsFrom;
            
            for i in 0..<needCoordsFrom.count {
                print("i is \(i) and needCoordsFrom.count is \(needCoordsFrom.count)");
                let player = needCoordsFrom[i];
                if players.contains(player) {
                    let coord = coordinates[needCoordsFrom[i]];
                    print("coord is \(coord)");
                    if coord?.latitude != 0 && coord?.longitude != 0 {
                        print("temp.count is")
                        temp.remove(at: i);
                        if didIntersect(oppName: player) {
                            print("did intersect")
                        }
                        else {
                            print("did not intersect");
                        }
                    }
                }
            }
            needCoordsFrom = temp;*/
        }
    }
    
    func didIntersect(oppName: String) -> Bool { //function checks to see if the opponent intersects with the player
        let oppCoord = coordinates[oppName];
        let userCoord = coordinates[userName];
        
        let latDiff = (oppCoord?.latitude)! - (userCoord?.latitude)!
        let longDiff = (oppCoord?.longitude)! - (userCoord?.longitude)!
        
        let angle = atan2(latDiff, longDiff) * (180/Double.pi);
        
        if (abs(heading! - angle) < angleErrorMargin) {
            return true;
        }
        return false;
    }
    
    var players: [String] = [] { //players who are in game
        didSet {
            if playersSender {
                
            }
            DispatchQueue.main.async {
                self.table.reloadData();
            }
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
            DispatchQueue.main.async {
                self.table.reloadData();
            }
        }
    }
    
    @IBAction func tagAction(_ sender: Any) {
        tagButton.isEnabled = false;
        shootAgain.text = "Shoot again in \(shotCountdownConst)"
        shotTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime(_:)), userInfo: nil, repeats: true)
        needCoordsFrom = players;
        let index = needCoordsFrom.index(of: userName)
        needCoordsFrom.remove(at: index!);
        MasterViewController.instance?.getCoordinates();
        //check for intersection 1 second after requesting data
        
        
        //fetch location data from other people
        //for location data in locationDataArray received
        //see if anything intersects
    }
    
    
    @objc func updateTime(_ sender: Any) {
        shotCountdownTime -= 1;
        shootAgain.text = "Shoot again in \(shotCountdownTime)"
        if (shotCountdownTime == 0) {
            shotTimer.invalidate();
            shotCountdownTime = shotCountdownConst;
            tagButton.isEnabled = true;
            shootAgain.text = "Shoot again in ..."
        }
    }
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GameViewController.instance = self
        
        coordinates[userName] = CLLocationCoordinate2DMake(37.785834000000001,-122.406417)//37.785834000000001, longitude: -122.406417)
        players = (RoomViewController.instance?.players)!;
        
        for player in players { //initialize all players with 5 lives
            playerLives[player] = 5;
        }
        
        //initialize time to constants
        shotCountdownTime = shotCountdownConst;
        gameCountdownTime = gameCountdownConst;
        
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
        
        gameEndTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(gameTimer), userInfo: nil, repeats: true)
        
    }
    
    func gameTimer() { //shows time in minutes
        if gameCountdownTime == 0 {
            gameEnd();
        }
        var temp = gameCountdownTime;
        let minutes = Int(floor(Double(temp/60)));
        temp = temp%60;
        timeLabel.text = "\(minutes):\(temp)"
        gameCountdownTime -= 1;
    }
    
    func gameEnd() {
        GameViewController.instance = nil;
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        //print(heading.magneticHeading)
        self.heading = heading.magneticHeading;
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //update location if location has changes
        if (lastPosition?.latitude != manager.location?.coordinate.latitude && lastPosition?.longitude != manager.location?.coordinate.longitude) {
            lastPosition = manager.location!.coordinate
            coordinates[userName] = lastPosition;
            print("locations = \((lastPosition?.latitude)!) \((lastPosition?.longitude)!)")
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
