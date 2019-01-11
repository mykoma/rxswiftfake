//
//  Skip.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/11.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func skip(_ count: Int) -> Observable<E> {
        return SkipCount(source: asObservable(), count: count)
    }
    
}

fileprivate final class SkipCount<ElementType>: Producer<ElementType> {
    
    private let _source: Observable<ElementType>
    
    private let _count: Int
    
    init(source: Observable<ElementType>, count: Int) {
        _source = source
        _count = count
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = SkipCountSink(count: _count, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class SkipCountSink<ElementType, O: ObserverType>: Sink<O>, ObserverType where O.E == ElementType {
    
    private var _remaining: Int
    
    init(count: Int, observer: O, cancel: Cancelable) {
        _remaining = count
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<ElementType>) {
        switch event {
        case .next(let value):
            if _remaining == 0 {
                forwardOn(.next(value))
            } else {
                _remaining -= 1
            }
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        case .completed:
            forwardOn(.completed)
            dispose()
        }
    }

}
