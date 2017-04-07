//
//  JSONEventStream.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-07.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//

import Foundation

class JSONEventStream: EventStream {
    
    var socket: Socket?
    let nl = "\n".data(using: .ascii)
    
    init(socket: Socket) {
        self.socket = socket
    }
    
    func get(data: Data) -> Event {
        var event: Event!;
        //print("getting...")
        let string = String(data: data, encoding: .ascii)!
        
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
        
        print("Data: \(string)");
        
        event = Event(stream: self, fields: json!)
        
        return event
    }
    
    func get() {
        socket?.readData(to: nl!, withTimeout: -1, tag: 0)
    }
    
    func put(event: Event) {
        let output = try? JSONSerialization.data(withJSONObject: event.fields, options: [])
        socket?.write(output!, withTimeout: -1, tag: 0)
        socket?.write(nl!, withTimeout: -1, tag: 0)
    }
    
    func close() {
        socket?.disconnect()
    }
}
