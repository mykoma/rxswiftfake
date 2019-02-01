//
//  InfiniteSequence.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/1.
//  Copyright © 2019 goluk. All rights reserved.
//

struct InfiniteSequence<E>: Sequence {
    
    private let _repeatedValue: E
    
    init(repeatedValue: E) {
        _repeatedValue = repeatedValue
    }
    
    func makeIterator() -> AnyIterator<E> {
        let repeatedValue = _repeatedValue
        return AnyIterator {
            return repeatedValue
        }
    }
    
}
