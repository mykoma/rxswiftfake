//
//  Filter.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/27.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func filter(_ predicate: @escaping (E) throws -> Bool) -> Observable<E> {
        return Filter(source: self.asObservable(), predicate: predicate)
    }
    
}

final fileprivate class Filter<ElementType>: Producer<ElementType> {
    typealias Predicate = (ElementType) throws -> Bool
    
    private let _source: Observable<ElementType>
    private let _predicate: Predicate
    
    init(source: Observable<ElementType>, predicate: @escaping Predicate) {
        _source = source
        _predicate = predicate
    }
    
    override func run<O>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where ElementType == O.E, O : ObserverType {
        let sink = FilterSink(predicate: _predicate, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
}

final fileprivate class FilterSink<O: ObserverType>: Sink<O>, ObserverType {
    
    typealias E = O.E
    typealias Predicate = (E) throws -> Bool
    
    private let _predicate: Predicate
    
    init(predicate: @escaping Predicate, observer: O, cancel: Cancelable) {
        _predicate = predicate
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<O.E>) {
        switch event {
        case .next(let value):
            do {
                let satisfies = try _predicate(value)
                if satisfies {
                    forwardOn(.next(value))
                }
            } catch let e {
                forwardOn(.error(e))
                dispose()
            }
        case .completed, .error:
            forwardOn(event)
            dispose()
        }
    }
    
}
