//
//  Rx.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

fileprivate var resourceCount = AtomicInt(0)

struct Resources {
    
    static var total: Int32 {
        return resourceCount.load()
    }
    
    static func incrementTotal() -> Int32 {
        return resourceCount.increment()
    }
    
    static func decrementTotal() -> Int32 {
        return resourceCount.decrement()
    }
    
}

func rxAbstractMethod(file: StaticString = #file, line: UInt = #line) -> Swift.Never {
    rxFatalError("Abstract method", file: file, line: line)
}

func rxFatalError(_ lastMessage: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) -> Swift.Never {
    fatalError(lastMessage(), file: file, line: line)
}
