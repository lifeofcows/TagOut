//
//  Connection.swift
//  COMP2601A4Client-101002578
//
//  Created by Maxim Kuzmenko on 2017-03-27.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//

import Foundation
import UIKit

//class for the person who initiates tic tac toe connection; opens up port on server (opponent) socket
/*
class Connection: NSObject, GCDAsyncSocketDelegate, Reactor {
    var socket: GCDAsyncSocket!
    var isConnected: Bool = false;
    var reactor = ReactorImpl();
    let dg = DispatchGroup()
    //static var instance: Connection?;
    var clientName: String!;
    var oppName: String!;
    
    func open(host: String, port:UInt16) {
        print("Opening socket connection with host (Server) \(host), port \(port)");
        socket = GCDAsyncSocket(delegate: self,
                                delegateQueue: DispatchQueue.main)
        do {
            try socket.connect(toHost: host, onPort: port)
            isConnected = true;
            print("Connected!");
            registerHandlers();
        } catch let e {
            print(e)
        }
    }
    //registers all the respective handlers
    func registerHandlers() {
        reactor.register(name: "PLAY_GAME_REQUEST",  handler: PlayGameRequest());
        reactor.register(name: "PLAY_GAME_RESPONSE", handler: PlayGameResponse());
        reactor.register(name: "GAME_ON",  handler: gameOn());
        reactor.register(name: "MOVE_MESSAGE", handler: moveMessage());
        reactor.register(name: "GAME_OVER",  handler: gameOver());
    }
    
    //sends initial play game req to server
    func socket(_ sock : GCDAsyncSocket,
                didConnectToHost host:String, port p:UInt16) {
        
        print("Connected to \(host) on port \(p).") //CONNECTED! NOW CAN SEND OBJECT
        clientName = MasterViewController.instance?.name;
        oppName = MasterViewController.instance?.oppName;
        MasterViewController.instance?.stream = JSONEventStream(socket: socket)
        Event(stream: JSONEventStream(socket: socket), fields: ["TYPE": "PLAY_GAME_REQUEST", "SOURCE": MasterViewController.instance?.name ?? "NULL", "DESTINATION": MasterViewController.instance?.oppName ?? "NULL"]).put();
        print("putting connection didConnectToHost event...");
        GameViewController.instance?.startButton.isEnabled = true;
        MasterViewController.instance?.player1 = true;
        print("This is player 1!")
        GameViewController.instance?.es = JSONEventStream(socket: socket);
        JSONEventStream(socket: sock).get();
    }
    
    //reads data from server
    func socket(_ sock: Socket, didRead data: Data, withTag tag: Int) {
        //print("Reading data... (on connection)");
        let clientData = JSONEventStream(socket: socket).get(data: data);
        //print("       got clientData... (on connection)")
        reactor.dispatch(event: clientData);
        //print("       dispatched clientData... (on connection)")
        JSONEventStream(socket: sock).get();
    }
    
    func register(name: String, handler: EventHandler) {
        reactor.register(name: name, handler: handler)
    }
    
    func deregister(name: String) {
        reactor.deregister(name: name)
    }
    
    func dispatch(event: Event) {
        reactor.dispatch(event: event)
    }
    //disconnects when user leaves game
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        MasterViewController.instance?.player1 = false;
        isConnected = false;
        print("Disconnected (connection)");
    }
}
 */
