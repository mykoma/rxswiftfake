//
//  Map.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/31.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func map<R>(_ transform: @escaping (E) throws -> R) -> Observable<R> {
        return Map(source: self.asObservable(), transform: transform)
    }
    
}

fileprivate final class Map<SourceType, ResultType>: Producer<ResultType> {
    
    typealias Transform = (SourceType) throws -> ResultType
    
    private let _source: Observable<SourceType>
    private let _transform: Transform
    
    init(source: Observable<SourceType>, transform: @escaping Transform) {
        _source = source
        _transform = transform
    }

    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ResultType {
        let sink = MapSink(transform: _transform, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }

}

fileprivate final class MapSink<SourceType, O: ObserverType>: Sink<O>, ObserverType {
    
    typealias ResultType = O.E
    typealias Transform = (SourceType) throws -> ResultType
    
    private let _transform: Transform
    
    init(transform: @escaping Transform, observer: O, cancel: Cancelable) {
        _transform = transform
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<SourceType>) {
        switch event {
        case .next(let value):
            do {
                let mappedElement = try _transform(value)
                forwardOn(.next(mappedElement))
            } catch let e {
                forwardOn(.error(e))
                dispose()
            }
        case .completed:
            forwardOn(.completed)
            dispose()
        case .error(let error):
            forwardOn(.error(error))
            dispose()
        }
    }
    
}
