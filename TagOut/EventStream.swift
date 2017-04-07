//
//  EventStream.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-07.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//

import Foundation

typealias Socket = GCDAsyncSocket
typealias SocketDelegate = GCDAsyncSocketDelegate

protocol EventStreamInput {
    func get()
    func get(data: Data) -> Event
}

protocol EventOutputStream {
    func put(event: Event)
}

protocol Closeable {
    func close()
}

protocol EventStream: EventStreamInput, EventOutputStream, Closeable {
}
