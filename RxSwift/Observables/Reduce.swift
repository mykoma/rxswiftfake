//
//  Reduce.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/13.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func reduce<A, R>(_ seed: A, accumulator: @escaping (A, E) throws -> A, mapResult: @escaping (A) throws -> R) -> Observable<R> {
        return Reduce(source: asObservable(), seed: seed, accumulator: accumulator, mapResult: mapResult)
    }

    func reduce<A>(_ seed: A, accumulator: @escaping (A, E) throws -> A) -> Observable<A> {
        return reduce(seed, accumulator: accumulator, mapResult: { $0 })
    }
    
}

fileprivate final class Reduce<SourceElementType, AccumulateType, ResultType>: Producer<ResultType> {
    
    typealias Source = Observable<SourceElementType>
    typealias Accumulator = (AccumulateType, SourceElementType) throws -> AccumulateType
    typealias MapResult = (AccumulateType) throws -> ResultType
    
    fileprivate let _source: Source
    fileprivate let _seed: AccumulateType
    fileprivate let _accumulator: Accumulator
    fileprivate let _mapResult: MapResult
    
    init(source: Source, seed: AccumulateType, accumulator: @escaping Accumulator, mapResult: @escaping MapResult) {
        _source = source
        _seed = seed
        _accumulator = accumulator
        _mapResult = mapResult
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ResultType {
        let sink = ReduceSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class ReduceSink<SourceElementType, AccumulateType, O: ObserverType>: Sink<O>, ObserverType {
    
    typealias Parent = Reduce<SourceElementType, AccumulateType, O.E>
    
    fileprivate let _parent: Parent
    fileprivate var _accumulation: AccumulateType
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        _accumulation = _parent._seed
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<SourceElementType>) {
        switch event {
        case .next(let value):
            do {
                _accumulation = try _parent._accumulator(_accumulation, value)
            } catch let e {
                forwardOn(.error(e))
                dispose()
            }
        case .error(let e):
            forwardOn(.error(e))
        case .completed:
            do {
                let result = try _parent._mapResult(_accumulation)
                forwardOn(.next(result))
                forwardOn(.completed)
                dispose()
            } catch let e {
                forwardOn(.error(e))
                dispose()
            }
        }
    }
    
}
