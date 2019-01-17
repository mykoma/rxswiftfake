//
//  DistinctUntilChanged.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/16.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType where E: Equatable {
    
    func distinctUntilChanged() -> Observable<E> {
        return self.distinctUntilChanged({ $0 }, comparer: { $0 == $1 })
    }
    
    func distinctUntilChanged(_ comparer: @escaping (E, E) throws -> Bool) -> Observable<E> {
        return self.distinctUntilChanged({ $0 }, comparer: comparer)
    }
    
    func distinctUntilChanged<K: Equatable>(_ keySelector: @escaping (E) -> (K)) -> Observable<E> {
        return self.distinctUntilChanged(keySelector, comparer: { $0 == $1 })
    }
    
    func distinctUntilChanged<K>(_ keySelector: @escaping (E) -> (K), comparer: @escaping (K, K) throws -> Bool) -> Observable<E> {
        return DistinctUntilChanged(source: asObservable(), keySelector: keySelector, comparer: comparer)
    }
    
}

fileprivate final class DistinctUntilChanged<ElementType, KeyType>: Producer<ElementType> {
    
    typealias Comparer = (KeyType, KeyType) throws -> Bool
    typealias KeySelector = (ElementType) throws -> KeyType
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _comparer: Comparer
    fileprivate let _keySelector: KeySelector
    
    init(source: Observable<ElementType>, keySelector: @escaping KeySelector, comparer: @escaping Comparer) {
        _source = source
        _keySelector = keySelector
        _comparer = comparer
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = DistinctUntilChangedSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class DistinctUntilChangedSink<KeyType, O: ObserverType>: Sink<O>, ObserverType {

    typealias Parent = DistinctUntilChanged<O.E, KeyType>
    
    fileprivate let _parent: Parent
    fileprivate var _currentKey: KeyType? = nil
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<O.E>) {
        switch event {
        case .next(let value):
            do {
                let key = try _parent._keySelector(value)
                var isEqual = false
                if let currentKey = _currentKey {
                    isEqual = try _parent._comparer(currentKey, key)
                }
                if isEqual {
                    return
                }
                _currentKey = key
                forwardOn(.next(value))
            } catch let e {
                forwardOn(.error(e))
                dispose()
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
