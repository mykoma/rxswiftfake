//
//  WithLatestFrom.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/22.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func withLatestFrom<SecondO: ObservableConvertibleType, R>(_ second: SecondO,
                                                               resultSelector: @escaping (E, SecondO.E) throws -> R) -> Observable<R> {
        return WithLatestFrom(first: asObservable(), second: second.asObservable(), resultSelector: resultSelector)
    }
    
}

extension ObservableType {
    
    func withLatestFrom<SecondO: ObservableConvertibleType, R>(_ second: SecondO) -> Observable<R> where SecondO.E == R {
        return WithLatestFrom(first: asObservable(), second: second.asObservable(), resultSelector: { $1 })
    }
    
}

fileprivate final class WithLatestFrom<FirstType, SecondType, R>: Producer<R> {
    
    typealias ResultSelector = (FirstType, SecondType) throws -> R
    
    fileprivate let _first: Observable<FirstType>
    fileprivate let _second: Observable<SecondType>
    fileprivate let _resultSelector: ResultSelector
    
    init(first: Observable<FirstType>, second: Observable<SecondType>, resultSelector: @escaping ResultSelector) {
        _first = first
        _second = second
        _resultSelector = resultSelector
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == R {
        let sink = WithLatestFromSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class WithLatestFromSink<FirstType, SecondType, O: ObserverType>: Sink<O>, ObserverType {

    typealias Parent = WithLatestFrom<FirstType, SecondType, O.E>

    fileprivate var _lock = RecursiveLock()
    fileprivate let _parent: Parent
    fileprivate var _secondLatestElement: SecondType?
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }

    func on(_ event: Event<FirstType>) {
        switch event {
        case .next(let value):
            guard let secondLatest = _secondLatestElement else { return }
            do {
                let result = try _parent._resultSelector(value, secondLatest)
                forwardOn(.next(result))
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
    
    func run() -> Disposable {
        let subscription = _parent._first.subscribe(self)
        let disposable = SingleAssignmentDisposable()
        let secondSink = WithLatestFromSecond(parent: self, disposable: disposable)
        disposable.setDisposable(_parent._second.subscribe(secondSink))
        return Disposables.create(subscription, disposable)
    }

}

fileprivate final class WithLatestFromSecond<FirstType, SecondType, O: ObserverType>: ObserverType, LockOwnerType, SynchronizedOnType {

    typealias E = SecondType
    typealias Parent = WithLatestFromSink<FirstType, SecondType, O>

    fileprivate let _parent: Parent
    fileprivate let _disposable: Disposable

    var _lock: RecursiveLock {
        return _parent._lock
    }

    init(parent: Parent, disposable: Disposable) {
        _parent = parent
        _disposable = disposable
    }

    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }

    func _synchronized_on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            _parent._secondLatestElement = value
        case .completed:
            _disposable.dispose()
        case .error(let e):
            _parent.forwardOn(.error(e))
            _parent.dispose()
        }
    }

}
