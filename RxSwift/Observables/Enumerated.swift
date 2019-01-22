//
//  Enumerated.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/22.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func enumerated() -> Observable<(index: Int, element: E)> {
        return Enumerated(source: asObservable())
    }
    
}

fileprivate final class Enumerated<ElementType>: Producer<(index: Int, element: ElementType)> {
    
    fileprivate let _source: Observable<ElementType>
    
    init(source: Observable<ElementType>) {
        _source = source
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == (index: Int, element: ElementType) {
        let sink = EnumeratedSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class EnumeratedSink<ElementType, O: ObserverType>
    : Sink<O>, ObserverType where O.E == (index: Int, element: ElementType) {
    
    typealias Parent = Enumerated<ElementType>
    
    fileprivate let _parent: Parent
    fileprivate var _index: Int = 0
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<ElementType>) {
        switch event {
        case .next(let value):
            forwardOn(.next((index: _index, element: value)))
            _index += 1
        case .completed:
            forwardOn(.completed)
            dispose()
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        }
    }

}
