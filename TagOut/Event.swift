//
//  Event.swift
//  Command-Server
//
//  Created by Tony White on 2017-03-15.
//  Copyright © 2017 Tony White. All rights reserved.
//

import Foundation

class Event : EventStream {
    var stream : EventStream
    var fields: [String: Any]
    
    init(stream: EventStream, fields: [String: Any]) {
        self.stream = stream
        self.fields = fields
    }
    
    func get() {
        stream.get()
    }
    
    func get(data: Data) -> Event {
        return stream.get(data: data)
    }
    
    func put(event: Event) {
        stream.put(event: event)
    }
    
    func put() {
        put(event: self)
    }
    
    func close() {
        stream.close()
    }
}
