//
//  GameViewController.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-09.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//

import UIKit
import CoreLocation

//The Game View: The actual Game. Uses CLLocation for the location data and the compass headings.
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
    let angleErrorMargin: Double = 20;
    var shotTimer: Timer = Timer();
    let shotCountdownConst: Int = 3;
    var shotCountdownTime: Int = -1;
    var gameEndTimer: Timer = Timer();
    var gameCountdownConst: Int = 400;
    var gameCountdownTime: Int = -1;
    var tagCount: Int = 0;
    var tagLives: Int = 3;
    let userName: String = (MasterViewController.instance?.userName!)!
    var lastPosition: CLLocationCoordinate2D!;
    
    static var instance: GameViewController?
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
                        DispatchQueue.main.async {
                            self.taggedLabel.text = "\(self.tagCount)"
                        }
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
        
        var angle = atan2(latDiff, longDiff)*(180/Double.pi)
        
        angle += 90;
        
        if angle < 0 {
            angle += 360
        }
        if angle > 360 {
            angle -= 360
        }
        
        angle = 180 - angle
        
        print("angle is \(angle), and abs(heading! - angle) is \(abs(heading! - angle)) and heading is \(heading!)")
        
        if (abs(heading! - angle) < angleErrorMargin) || (360 - abs(heading! - angle) < angleErrorMargin) {
            return true;
        }
        return false;
    }
    
    var players: [String] = [] { //players who are in game
        didSet {
            if players.count == 1 { //if one person left in the game, send game end message
                GameViewController.instance = nil;
                gameEnd(message: "The Game has Ended! \(players[0]) has won.");
            }
        }
    }
    
    var playerLives: [String : Int] = [:] {
        didSet {
            if playerLivesSender {
                MasterViewController.instance?.updatePlayerLives(playerLives: playerLives);
                playerLivesSender = false;
            }
            if playerLives.count == players.count { //once game has loaded
                if playerLives[userName]! != nil {
                    tagLives = playerLives[userName]!;
                }
                for i in 0..<players.count { //remove player lives
                    if playerLives[players[i]] == 0 {
                        playerLives[players[i]] = nil
                        players.remove(at: i);
                    }
                }
                players = players.sorted(by: {(p1: String, p2: String) -> Bool in //sort players by player lives in descending order
                    return (playerLives[p1]! > playerLives[p2]!);
                })
                DispatchQueue.main.async {
                    self.tagLivesLabel.text = "\(self.tagLives)";
                }
                if tagLives < 1 {//game over
                    gameEnd(message: "You ran out of lives! You are now a spectator.");
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
        
        //(test coordinates for the computer)
        coordinates[userName] = CLLocationCoordinate2DMake(45.310813, -75.926181)//45.3118419601073  -75.9262920544259
        
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
        
        self.locationManager.requestWhenInUseAuthorization() //ask user to use when in use
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
        GameViewController.instance = nil;
    }
    
    func gameTimer() { //shows time in minutes
        if gameCountdownTime == 0 {
            gameEnd(message: "The Game has Ended! \(players[0]) has won.");
        }
        var temp = gameCountdownTime;
        let minutes = Int(floor(Double(temp/60)));
        temp = temp%60;
        if temp < 10 {
            DispatchQueue.main.async {
                self.timeLabel.text = "\(minutes):0\(temp)"
            }
        }
        else {
            DispatchQueue.main.async {
                self.timeLabel.text = "\(minutes):\(temp)"
            }
        }
        gameCountdownTime -= 1;
    }
    
    func gameEnd(message: String) {
        let alert = UIAlertController(title: "Game Over", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let OK = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: { (_) -> Void in
            if self.players.count < 2 || self.gameCountdownTime < 1 {
                _ = self.navigationController?.popViewController(animated: true)
            }
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
        if Int(round((manager.location?.coordinate.latitude)!)) != 38 && ((manager.location?.horizontalAccuracy)! < Double(10)) { //have to fix computer redirection coordinates for testing
            lastPosition = manager.location!.coordinate
            coordinates[userName] = lastPosition;
            //print("locations = \((lastPosition?.latitude)!) \((lastPosition?.longitude)!)")
            //print("horizontal accuracy is \(manager.location?.horizontalAccuracy)")
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

//STOPS AS CONNECTS, THEN DIDRECEIVE INVITATION FROM PEER
