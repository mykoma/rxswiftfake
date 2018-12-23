//
//  AnyObserver.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/21.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation


// AnyObserver存在的意义是
// 1. 包装传入的observer的on方法，
// 2. 包装 (Event<E>) -> Void这样的方法
struct AnyObserver<ElementType>: ObserverType {
    
    typealias E = ElementType
    
    typealias EventHandler = (Event<E>) -> Void
    
    private let observer: EventHandler
    
    init(eventHandler: @escaping EventHandler) {
        self.observer = eventHandler
    }
    
    init<O: ObserverType>(_ observer: O) where O.E == E {
        self.observer = observer.on
    }
    
    func on(_ event: Event<E>) {
        self.observer(event)
    }
    
    func asObserver() -> AnyObserver<E> {
        return self
    }
    
}

extension AnyObserver {
    
    typealias s = Bag<(Event<E>) -> Void>
    
}

extension ObserverType {
    
    func asObserver() -> AnyObserver<E> {
        return AnyObserver(self)
    }
    
}
