//
//  Switch.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/21.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func flatMapLatest<O: ObservableConvertibleType>(_ selector: @escaping (E) throws -> O) -> Observable<O.E> {
        return FlatMapLatest(source: asObservable(), selector: selector)
    }
    
}

extension ObservableType where E: ObservableConvertibleType {
    
    func switchLatest() -> Observable<E.E> {
        return Switch(source: asObservable())
    }
    
}

fileprivate final class Switch<S: ObservableConvertibleType>: Producer<S.E> {
    
    fileprivate let _source: Observable<S>
    
    init(source: Observable<S>) {
        _source = source
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == S.E {
        let sink = SwitchIdentitySink<S, O>(observer: observer, cancel: cancel)
        let subscription = sink.run(_source)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate class SwitchSink<SourceElementType, S: ObservableConvertibleType, O: ObserverType>: Sink<O>, ObserverType where S.E == O.E {
    
    typealias E = SourceElementType
    
    fileprivate let _subscription = SingleAssignmentDisposable()
    fileprivate let _innerSubscription = SerialDisposable()
    
    func performMap(_ element: SourceElementType) throws -> S {
        rxAbstractMethod()
    }
    
    func on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            do {
                let observable = try performMap(value)
                let sinkIter = SwitchSinkIter(parent: self)
                let subscription = observable.asObservable().subscribe(sinkIter)
                _innerSubscription.disposable = subscription
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
    
    func run(_ source: Observable<SourceElementType>) -> Disposable {
        let subscrption = source.subscribe(self)
        _subscription.setDisposable(subscrption)
        return Disposables.create(_subscription, _innerSubscription)
    }
    
}

fileprivate final class SwitchIdentitySink<S: ObservableConvertibleType, O: ObserverType>: SwitchSink<S, S, O> where S.E == O.E {
    
    override func performMap(_ element: S) throws -> S {
        return element
    }
    
}

fileprivate final class SwitchSinkIter<SourceElementType, S: ObservableConvertibleType, O: ObserverType>: ObserverType where S.E == O.E {

    typealias Parent = SwitchSink<SourceElementType, S, O>

    fileprivate let _parent: Parent

    init(parent: Parent) {
        _parent = parent
    }

    func on(_ event: Event<O.E>) {
        _parent.forwardOn(event)
        switch event {
        case .next:
            break
        case .completed, .error:
            _parent.dispose()
        }
    }

}

fileprivate final class FlatMapLatest<SourceElementType, S: ObservableConvertibleType>: Producer<S.E> {
    
    typealias Selector = (SourceElementType) throws -> S
    
    fileprivate let _selector: Selector
    fileprivate let _source: Observable<SourceElementType>
    
    init(source: Observable<SourceElementType>, selector: @escaping Selector) {
        _source = source
        _selector = selector
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == S.E {
        let sink = FlatMapLatestSink<SourceElementType, S, O>(selector: _selector, observer: observer, cancel: cancel)
        let subscription = sink.run(_source)
        return (sink: sink, subscription: subscription)
    }

}

fileprivate final class FlatMapLatestSink<SourceElementType, S: ObservableConvertibleType, O: ObserverType>: SwitchSink<SourceElementType, S, O> where S.E == O.E {
    
    typealias Selector = (SourceElementType) throws -> S

    fileprivate let _selector: Selector
    
    init(selector: @escaping Selector, observer: O, cancel: Cancelable) {
        _selector = selector
        super.init(observer: observer, cancel: cancel)
    }

    override func performMap(_ element: SourceElementType) throws -> S {
        return try _selector(element)
    }

}

