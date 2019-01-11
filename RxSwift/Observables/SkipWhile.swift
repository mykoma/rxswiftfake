//
//  SkipWhile.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/11.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func skipWhile(_ predicate: @escaping (E) -> Bool ) -> Observable<E> {
        return SkipWhile(source: asObservable(), predicate: predicate)
    }
    
}

fileprivate final class SkipWhile<ElementType>: Producer<ElementType> {
    
    typealias Predicate = (ElementType) throws -> Bool

    fileprivate let _source: Observable<ElementType>
    fileprivate let _predicate: Predicate
    
    init(source: Observable<ElementType>, predicate: @escaping Predicate) {
        _source = source
        _predicate = predicate
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = SkipWhileSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class SkipWhileSink<ElementType, O: ObserverType>: Sink<O>, ObserverType where ElementType == O.E {

    typealias Parent = SkipWhile<ElementType>
    
    fileprivate let _parent: Parent
    fileprivate var _running = false

    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<ElementType>) {
        switch event {
        case .next(let value):
            if !_running {
                do {
                    _running = try _parent._predicate(value)
                } catch let e {
                    forwardOn(.error(e))
                    dispose()
                    return
                }
            }
            if _running {
                forwardOn(.next(value))
            }
        case .completed, .error:
            forwardOn(event)
            dispose()
        }
    }

}
