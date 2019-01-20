//
//  DefaultIfEmpty.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/20.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func ifEmpty(default: E) -> Observable<E> {
        return DefaultIfEmpty(source: asObservable(), default: `default`)
    }
    
}

fileprivate final class DefaultIfEmpty<ElementType>: Producer<ElementType> {
    
    fileprivate let _default: ElementType
    fileprivate let _source: Observable<ElementType>
    
    init(source: Observable<ElementType>, default: ElementType) {
        _source = source
        _default = `default`
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = DefaultIfEmptySink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class DefaultIfEmptySink<ElementType, O: ObserverType>: Sink<O>, ObserverType where ElementType == O.E {

    typealias Parent = DefaultIfEmpty<ElementType>
    
    fileprivate let _parent: Parent
    fileprivate var _isEmpty = true
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<ElementType>) {
        switch event {
        case .next(let value):
            _isEmpty = false
            forwardOn(.next(value))
        case .completed:
            if _isEmpty {
                forwardOn(.next(_parent._default))
            }
            forwardOn(.completed)
            dispose()
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        }
    }

}
