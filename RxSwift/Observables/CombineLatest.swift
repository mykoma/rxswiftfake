//
//  CombineLatest.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/18.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    static func combineLatest<O1: ObservableType, O2: ObservableType>(_ source1: O1, _ source2: O2, resultSelector: @escaping (O1.E, O2.E) throws -> E) -> Observable<E> {
        return CombineLatest(source1: source1.asObservable(), source2: source2.asObservable(), resultSelector: resultSelector)
    }
    
}

fileprivate final class CombineLatest<E1, E2, ElementType>: Producer<ElementType> {
    
    typealias ResultSelector = (E1, E2) throws -> ElementType
    
    fileprivate let _source1: Observable<E1>
    fileprivate let _source2: Observable<E2>
    fileprivate let _resultSelector: ResultSelector
    
    init(source1: Observable<E1>, source2: Observable<E2>, resultSelector: @escaping ResultSelector) {
        _source1 = source1
        _source2 = source2
        _resultSelector = resultSelector
    }

    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable)
        -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
            let sink = CombineLatestSink(parent: self, observer: observer, cancel: cancel)
            let subscription = sink.run()
            return (sink: sink, subscription: subscription)
    }
}

fileprivate final class CombineLatestSink<E1, E2, ElementType, O: ObserverType>: Sink<O> where O.E == ElementType {
    
    typealias Parent = CombineLatest<E1, E2, ElementType>
    
    let _lock = RecursiveLock()
    fileprivate let _parent: Parent
    
    fileprivate var _latestElement1: E1?
    fileprivate var _latestElement2: E2?

    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func run() -> Disposable {
        let subscription1 = SingleAssignmentDisposable()
        let subscription2 = SingleAssignmentDisposable()
        
        let observer1 = CombineLatestObserver(lock: _lock, setLatestValue: { (value: E1) in
            self._latestElement1 = value
            self.forwardLatest()
        }, dispose: subscription1)
        subscription1.setDisposable(_parent._source1.subscribe(observer1))
        
        let observer2 = CombineLatestObserver(lock: _lock, setLatestValue: { (value: E2) in
            self._latestElement2 = value
            self.forwardLatest()
        }, dispose: subscription2)
        subscription2.setDisposable(_parent._source2.subscribe(observer2))
        return Disposables.create(subscription1, subscription2)
    }
    
    func forwardLatest() {
        guard let latestElement1 = _latestElement1, let latestElement2 = _latestElement2 else {
            return
        }
        do {
            let value = try _parent._resultSelector(latestElement1, latestElement2)
            self.forwardOn(.next(value))
        } catch let e {
            forwardOn(.error(e))
            dispose()
        }
    }
    
}

fileprivate final class CombineLatestObserver<SourceElementType>: ObserverType, LockOwnerType, SynchronizedOnType {

    typealias ValueSelector = (SourceElementType) -> Void

    var _lock: RecursiveLock
    private let _setLatestValue: ValueSelector
    private let _dispose: Disposable

    init(lock: RecursiveLock, setLatestValue: @escaping ValueSelector, dispose: Disposable) {
        _lock = lock
        _setLatestValue = setLatestValue
        _dispose = dispose
    }

    func on(_ event: Event<SourceElementType>) {
        synchronizedOn(event)
    }

    func _synchronized_on(_ event: Event<SourceElementType>) {
        switch event {
        case .next(let value):
            _setLatestValue(value)
        case .error(let error):
            _dispose.dispose()
        case .completed:
            _dispose.dispose()
        }
    }

}
