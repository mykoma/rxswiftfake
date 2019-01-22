//
//  ToArray.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/22.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func toArray() -> Observable<[E]> {
        return ToArray(source: asObservable())
    }
    
}

fileprivate final class ToArray<SourceType>: Producer<[SourceType]> {
    
    fileprivate let _source: Observable<SourceType>
    
    init(source: Observable<SourceType>) {
        _source = source
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == [SourceType] {
        let sink = ToArraySink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class ToArraySink<SourceType, O: ObserverType>: Sink<O>, ObserverType where O.E == [SourceType] {
    
    typealias Parent = ToArray<SourceType>
    
    fileprivate let _parent: Parent
    fileprivate var _list = [SourceType]()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<SourceType>) {
        switch event {
        case .next(let value):
            _list.append(value)
        case .completed:
            forwardOn(.next(_list))
            forwardOn(.completed)
            dispose()
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        }
    }

}
