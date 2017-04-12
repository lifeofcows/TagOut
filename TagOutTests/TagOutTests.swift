//
//  TagOutTests.swift
//  TagOutTests
//
//  Created by Maxim Kuzmenko on 2017-04-07.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//

import XCTest
import CoreLocation

@testable import TagOut

class TagOutTests: XCTestCase {
    
    var master: MasterViewController = MasterViewController();
    var room: RoomViewController!;
    var game: GameViewController!;
    var players = ["Bob", "Andy"];
    var playersLives = ["Bob": 5, "Andy": 5]
    var coordinates = ["Bob" : CLLocationCoordinate2DMake(45.310813000000003, -75.926181), "Andy": CLLocationCoordinate2DMake(45.311749172439157, -75.926238745521687)]
    
    override func setUp() {
        super.setUp()
        
        master.userName = "Andy";
        room = RoomViewController();
        game = GameViewController();
        game.players = players;
        game.playerLives = playersLives;
        game.heading = 195.980346679688;
        
        XCTAssertEqual(true, game.didIntersect(oppName: "Bob")) //Basic testing
        game.heading = 240
        XCTAssertEqual(false, game.didIntersect(oppName: "Bob")) //Basic testing
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
