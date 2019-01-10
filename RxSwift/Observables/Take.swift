//
//  Take.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/10.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func take(_ count: Int) -> Observable<E> {
        if count == 0 {
            return Observable.empty()
        } else {
            return TakeCount(source: asObservable(), count: count)
        }
    }
    
}

fileprivate final class TakeCount<ElementType>: Producer<ElementType> {
    
    fileprivate let _count: Int
    
    fileprivate let _source: Observable<ElementType>
    
    init(source: Observable<ElementType>, count: Int) {
        _count = count
        _source = source
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = TakeCountSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class TakeCountSink<ElementType, O: ObserverType>: Sink<O>, ObserverType where O.E == ElementType {

    fileprivate let _parent: TakeCount<ElementType>

    fileprivate var _remaining: Int
    
    init(parent: TakeCount<ElementType>, observer: O, cancel: Cancelable) {
        _parent = parent
        _remaining = _parent._count
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<ElementType>) {
        switch event {
        case .next(let element):
            if _remaining > 0 {
                _remaining -= 1
                forwardOn(.next(element))
                if _remaining == 0 {
                    forwardOn(.completed)
                    dispose()
                }
            }
        case .error(let error):
            forwardOn(.error(error))
            dispose()
        case .completed:
            forwardOn(.completed)
            dispose()
        }
    }
}
