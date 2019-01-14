//
//  Scan.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/14.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func scan<A>(_ seed: A, accumulator: @escaping (A, E) throws -> A) -> Observable<A> {
        return Scan(source: asObservable(), seed: seed, accumulator: accumulator)
    }
    
}

fileprivate final class Scan<SourceElementType, A>: Producer<A> {
    
    typealias Accumulator = (A, SourceElementType) throws -> A
    
    fileprivate let _source: Observable<SourceElementType>
    fileprivate let _accumulator: Accumulator
    fileprivate let _seed: A
    
    init(source: Observable<SourceElementType>, seed: A, accumulator: @escaping Accumulator) {
        _source = source
        _seed = seed
        _accumulator = accumulator
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == A {
        let sink = ScanSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class ScanSink<SourceElementType, O: ObserverType>: Sink<O>, ObserverType {
    
    typealias Accumulate = O.E
    typealias Parent = Scan<SourceElementType, Accumulate>
    
    fileprivate let _parent: Parent
    fileprivate var _accumulate: Accumulate
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        _accumulate = _parent._seed
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<SourceElementType>) {
        switch event {
        case .next(let value):
            do {
                _accumulate = try _parent._accumulator(_accumulate, value)
                forwardOn(.next(_accumulate))
            } catch let e {
                forwardOn(.error(e))
                dispose()
            }
        case .completed:
            forwardOn(.completed)
            dispose()
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        }
    }
    
}
