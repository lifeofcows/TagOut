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
    //locations = 45.3117417544549 -75.9263544157855
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var shootAgain: UILabel!
    @IBOutlet weak var tagLivesLabel: UILabel!
    @IBOutlet weak var taggedLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    var playersSender: Bool = false;
    var playerLivesSender: Bool = false;
    var heading: CLLocationDirection? = nil;
    let angleErrorMargin: Double = 10;
    var shotTimer: Timer = Timer();
    let shotCountdownConst: Int = 5;
    var shotCountdownTime: Int = -1;
    var gameEndTimer: Timer = Timer();
    var gameCountdownConst: Int = 10;
    var gameCountdownTime: Int = -1;
    var tagCount: Int = 0;
    var tagLives: Int = 3;
    let userName: String = (MasterViewController.instance?.userName!)!
    var lastPosition: CLLocationCoordinate2D!;
    
    static var instance: GameViewController?
    var needCoordsFrom: [String] = []
    var coordinates: [String: CLLocationCoordinate2D] = [:] { //name andcoordinates. array of players: inside, array of data (0th index = name, 1st is coords))
        didSet {
            if oldValue.count >= coordinates.count || oldValue.count == 0 {
                return;
            }
            
            let newPlayers = Set(coordinates.keys)
            let oldPlayers = Set(oldValue.keys);
            
            let checkPlayers = Array(newPlayers.symmetricDifference(oldPlayers)); //find players who need to be checked
            
            print("checkPlayers is \(checkPlayers)")
            
            for player in checkPlayers {
                let coord = coordinates[player];
                if coord?.latitude != 0 && coord?.longitude != 0 {
                    if didIntersect(oppName: player) {
                        print("did intersect");
                        tagCount += 1;
                        taggedLabel.text = "\(tagCount)"
                        let lives = playerLives[player]! - 1;
                        playerLivesSender = true;
                        playerLives[player] = lives
                    }
                    else {
                        print("did not intersect");
                    }
                }
            }
            
            if coordinates.count + 1 >= players.count {
                print("clearing coordinates dict...")
                coordinates = [:]
                coordinates[userName] = lastPosition;
            }
        }
    }
    
    func didIntersect(oppName: String) -> Bool { //function checks to see if the opponent intersects with the player
        let oppCoord = coordinates[oppName];
        let userCoord = coordinates[userName];
        
        print("oppCoord is \(oppCoord!) and userCoord is \(userCoord!)")
        
        let latDiff = (oppCoord?.latitude)! - (userCoord?.latitude)!
        let longDiff = (oppCoord?.longitude)! - (userCoord?.longitude)!
        
        print("latDiff is \(latDiff) and longDiff is \(longDiff)")
        
        var angle = atan2(latDiff, longDiff) * (180/Double.pi);
        
        if angle < 0 {
            angle += 360
        }
        
        //print("latDiff is \(latDiff) and longDiff is \(longDiff)");
        
        print("angle is \(angle), and abs(heading! - angle) is \(abs(heading! - angle)) and heading is \(heading!)")
        
        if (abs(heading! - angle) < angleErrorMargin) {
            return true;
        }
        return false;
    }
    
    var players: [String] = [] { //players who are in game
        didSet {
            if playersSender {
                
            }
            if players.count == 1 { //if one person left in the game, send game end message
                gameEnd();
            }
            DispatchQueue.main.async {
                self.table.reloadData();
            }
        }
    }
    
    var playerLives: [String : Int] = [:] {
        didSet {
            players = players.sorted(by: {(p1: String, p2: String) -> Bool in
                return (playerLives[p1]! < playerLives[p2]!);
            })
            for i in 0..<players.count { //remove player lives
                if playerLives[players[i]] == 0 {
                    players.remove(at: i);
                }
            }
            if playerLivesSender {
                MasterViewController.instance?.updatePlayerLives(playerLives: playerLives);
                playerLivesSender = false;
            }
            DispatchQueue.main.async {
                self.table.reloadData();
            }
        }
    }
    
//    func didGetTagged() {
//        tagLives -= 1
//        tagLivesLabel.text = "\(tagLives)"
//        if (tagLives == 0) { //spectate
//            
//        }
//    }
    
    @IBAction func tagAction(_ sender: Any) {
        tagButton.isEnabled = false;
        shootAgain.text = "Shoot again in \(shotCountdownConst)"
        shotTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime(_:)), userInfo: nil, repeats: true)
        needCoordsFrom = players;
        let index = needCoordsFrom.index(of: userName)
        needCoordsFrom.remove(at: index!);
        MasterViewController.instance?.getCoordinates();
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
        
        coordinates[userName] = CLLocationCoordinate2DMake(45.311717656483232,-75.92637570581951)//45.311717656483232, longitude: -75.92637570581951
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
        if temp < 10 {
            timeLabel.text = "\(minutes):0\(temp)"
        }
        else {
            timeLabel.text = "\(minutes):\(temp)"
        }
        gameCountdownTime -= 1;
    }
    
    func gameEnd() { //UNCOMMENT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        GameViewController.instance = nil;
        let alert = UIAlertController(title: "The Game has Ended! \(players[0]) has won.", message: "", preferredStyle: UIAlertControllerStyle.alert)
        let OK = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: { (_) -> Void in
            _ = self.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(OK);
        self.present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        //print(heading.magneticHeading)
        self.heading = heading.magneticHeading;
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //update location if location has changes
        //if (lastPosition?.latitude != manager.location?.coordinate.latitude && lastPosition?.longitude != manager.location?.coordinate.longitude) {
            if Int(round((manager.location?.coordinate.latitude)!)) != 38 { //have to fix computer redirection coordinates for testing
                lastPosition = manager.location!.coordinate
                coordinates[userName] = lastPosition;
                print("locations = \((lastPosition?.latitude)!) \((lastPosition?.longitude)!)")
            }
        //}
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
