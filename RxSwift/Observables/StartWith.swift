//
//  StartWith.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/15.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func startWith(_ elements: E ...) -> Observable<E> {
        return StartWith(source: asObservable(), elements: elements)
    }
    
}

fileprivate final class StartWith<ElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _elements: [ElementType]
    
    init(source: Observable<ElementType>, elements: [ElementType]) {
        _source = source
        _elements = elements
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        for e in _elements {
            observer.on(.next(e))
        }
        let sink = Disposables.create()
        let subscription = _source.subscribe(observer)
        return (sink: sink, subscription: subscription)
    }
    
}
