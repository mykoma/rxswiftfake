//
//  Bag+Rx.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/21.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

@inline(__always)
func dispatch<E>(_ bag: Bag<(Event<E>) -> Void>, _ event: Event<E>) {
    bag._value0?(event)
    if bag._onlyFastPath {
        return
    }
    
    let pairs = bag._pairs
    for i in 0 ..< pairs.count {
        pairs[i].value(event)
    }
    
    if let dictionary = bag._dictionary {
        for element in dictionary.values {
            element(event)
        }
    }
}
