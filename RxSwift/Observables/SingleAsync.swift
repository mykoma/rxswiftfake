//
//  SingleAsync.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/3.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    func single(_ predicate: ((E) throws -> Bool)? = nil) -> Observable<E> {
        return SingleAsync(source: asObservable(), predicate: predicate)
    }
    
}

fileprivate final class SingleAsync<E>: Producer<E> {
    
    fileprivate let _source: Observable<E>
    fileprivate let _predicate: ((E) throws -> Bool)?
    
    init(source: Observable<E>, predicate: ((E) throws -> Bool)?) {
        _source = source
        _predicate = predicate
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == E {
        let sink = SingleAsyncSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class SingleAsyncSink<O: ObserverType>: Sink<O>, ObserverType {
    
    typealias E = O.E
    typealias Parent = SingleAsync<E>
    
    fileprivate let _parent: Parent
    fileprivate var _seenValue = false
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            do {
                let forward = try _parent._predicate?(value) ?? true
                if !forward {
                    return
                }
            } catch let e {
                forwardOn(.error(e))
                dispose()
                return
            }
            if _seenValue {
                forwardOn(.error(RxError.moreThanOneElement))
                dispose()
                return
            }
            
            forwardOn(.next(value))
            _seenValue = true
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        case .completed:
            if _seenValue {
                forwardOn(.completed)
            } else {
                forwardOn(.error(RxError.noElements))
            }
            dispose()
        }
    }

}
