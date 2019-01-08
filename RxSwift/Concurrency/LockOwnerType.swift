//
//  LockOwnerType.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/8.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

protocol LockOwnerType: class, Lock {
    
    var _lock: RecursiveLock { get }
    
}

extension LockOwnerType {
    
    func lock() {
        _lock.lock()
    }
    
    func unlock() {
        _lock.unlock()
    }
    
}
