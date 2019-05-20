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
    
    fileprivate let _subscriptions = SingleAssignmentDisposable()
    fileprivate let _innerSubscription = SerialDisposable()
    
    let _lock = RecursiveLock()
    
    // state
    fileprivate var _stopped = false
    fileprivate var _latest = 0
    fileprivate var _hasLatest = false
    
    func performMap(_ element: SourceElementType) throws -> S {
        rxAbstractMethod()
    }
    
    @inline(__always)
    final private func nextElementArrived(element: E) -> (Int, Observable<S.E>)? {
        _lock.lock(); defer { _lock.unlock() } // {
        do {
            let observable = try performMap(element).asObservable()
            _hasLatest = true
            _latest = _latest &+ 1
            return (_latest, observable)
        }
        catch let error {
            forwardOn(.error(error))
            dispose()
        }
        
        return nil
        // }
    }
    
    func on(_ event: Event<E>) {
        switch event {
        case .next(let element):
            if let (latest, observable) = nextElementArrived(element: element) {
                let d = SingleAssignmentDisposable()
                _innerSubscription.disposable = d
                
                let observer = SwitchSinkIter(parent: self, id: latest, _self: d)
                let disposable = observable.subscribe(observer)
                d.setDisposable(disposable)
            }
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        case .completed:
            _lock.lock(); defer { _lock.unlock() }
            _stopped = true
            
            _subscriptions.dispose()
            
            if !_hasLatest {
                forwardOn(.completed)
                dispose()
            }
        }
    }
    
    func run(_ source: Observable<SourceElementType>) -> Disposable {
        let subscrption = source.subscribe(self)
        _subscriptions.setDisposable(subscrption)
        return Disposables.create(_subscriptions, _innerSubscription)
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
    fileprivate let _id: Int
    fileprivate let _self: Disposable
    
    init(parent: Parent, id: Int, _self: Disposable) {
        _parent = parent
        _id = id
        self._self = _self
    }

    func on(_ event: Event<O.E>) {
        switch event {
        case .next:
            _parent.forwardOn(event)
        case .completed:
            _parent._hasLatest = false
            if _parent._stopped {
                _parent.forwardOn(event)
                _parent.dispose()
            }
        case .error:
            _parent.forwardOn(event)
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

