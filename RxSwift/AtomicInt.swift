//
//  AtomicInt.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/21.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

extension AtomicInt {
    
    init(_ initialValue: Int32) {
        self.init()
        self.initialize(initialValue)
    }
    
    @discardableResult
    mutating func increment() -> Int32 {
        return self.add(1)
    }
    
    @discardableResult
    mutating func decrement() -> Int32 {
        return self.sub(1)
    }
    
    mutating func isFlagSet(_ mask: Int32) -> Bool {
        return (self.load() & mask) != 0
    }
    
}
