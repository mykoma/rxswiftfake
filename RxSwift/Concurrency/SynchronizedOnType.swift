//
//  SynchronizedOnType.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/8.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

protocol SynchronizedOnType: class, ObserverType, Lock {
    
    func _synchronized_on(_ event: Event<E>)
    
}

extension SynchronizedOnType {
    
    func synchronizedOn(_ event: Event<E>) {
        lock(); defer { unlock() }
        _synchronized_on(event)
    }
    
}
