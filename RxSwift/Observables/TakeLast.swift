//
//  TakeLast.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/10.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func takeLast(_ count: Int) -> Observable<E> {
        return TakeLast(source: asObservable(), count: count)
    }
    
}

fileprivate final class TakeLast<ElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    
    fileprivate let _count: Int
    
    init(source: Observable<ElementType>, count: Int) {
        _source = source
        _count = count
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = TakeLastSink(count: _count, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class TakeLastSink<ElementType, O: ObserverType>: Sink<O>, ObserverType where ElementType == O.E {
    
    fileprivate let _count: Int
    
    fileprivate var _queue: Queue<ElementType>
    
    init(count: Int, observer: O, cancel: Cancelable) {
        _count = count
        _queue = Queue<ElementType>(capacity: count + 1)
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<ElementType>) {
        switch event {
        case .next(let value):
            _queue.enqueue(value)
            if _queue.count > _count {
                _queue.dequeue()
            }
        case .error(let error):
            forwardOn(.error(error))
            dispose()
        case .completed:
            for e in _queue {
                forwardOn(.next(e))
            }
            forwardOn(.completed)
            dispose()
        }
    }
    
}
