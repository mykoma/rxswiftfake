//
//  ElementAt.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/15.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func elementAt(_ index: Int) -> Observable<E> {
        return ElementAt(source: asObservable(), index: index)
    }
    
}

fileprivate final class ElementAt<ElementType>: Producer<ElementType> {

    fileprivate let _index: Int
    fileprivate let _source: Observable<ElementType>
    
    init(source: Observable<ElementType>, index: Int) {
        _source = source
        _index = index
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = ElementAtSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class ElementAtSink<ElementType, O: ObserverType>: Sink<O>, ObserverType where O.E == ElementType {
    
    typealias Parent = ElementAt<ElementType>
    
    fileprivate let _parent: Parent
    private var _i: Int
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        _i = _parent._index
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<ElementType>) {
        switch event {
        case .next(let value):
            if _i == 0 {
                forwardOn(.next(value))
                forwardOn(.completed)
                dispose()
            }
            
            do {
                let _ = try decrementChecked(&_i)
            } catch let e {
                forwardOn(.error(e))
                dispose()
                return
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
