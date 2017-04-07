//
//  Reactor.swift
//  TagOut
//
//  Created by Maxim Kuzmenko on 2017-04-07.
//  Copyright © 2017 Maxim Kuzmenko. All rights reserved.
//

import Foundation

protocol Reactor {
    func register(name: String, handler: EventHandler)
    func deregister(name: String)
    func dispatch(event: Event)
}
