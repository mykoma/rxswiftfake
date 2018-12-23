//
//  RecursiveLock.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/21.
//  Copyright © 2018 goluk. All rights reserved.
//

import class Foundation.NSRecursiveLock

class RecursiveLock: NSRecursiveLock {
    override init() {
        _ = Resources.incrementTotal()
    }
    
    override func lock() {
        super.lock()
        _ = Resources.incrementTotal()
    }
    
    override func unlock() {
        super.unlock()
        _ = Resources.decrementTotal()
    }
    
    deinit {
        _ = Resources.decrementTotal()
    }
    
}


