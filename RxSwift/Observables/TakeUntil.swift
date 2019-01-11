//
//  TakeUntil.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/11.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func takeUntil<O: ObservableConvertibleType>(_ other: O) -> Observable<E> {
        return TakeUntil(source: asObservable(), other: other.asObservable())
    }
    
}

fileprivate final class TakeUntil<ElementType, OtherElementType>: Producer<ElementType> {
    
    fileprivate let _other: Observable<OtherElementType>
    fileprivate let _source: Observable<ElementType>

    init(source: Observable<ElementType>, other: Observable<OtherElementType>) {
        _source = source
        _other = other
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = TakeUntilSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class TakeUntilSink<OtherElementType, O: ObserverType>: Sink<O>, ObserverType, LockOwnerType, SynchronizedOnType {
    
    typealias E = O.E
    typealias Parent = TakeUntil<E, OtherElementType>
    
    fileprivate let _lock = RecursiveLock()
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }
    
    func _synchronized_on(_ event: Event<O.E>) {
        switch event {
        case .next:
            forwardOn(event)
        case .completed:
            forwardOn(event)
            dispose()
        case .error:
            forwardOn(event)
            dispose()
        }
    }
    
    func run() -> Disposable {
        let otherObserver = TakeUntilSinkOther(parent: self)
        let otherSubscription = _parent._other.subscribe(otherObserver)
        otherObserver._subscription.setDisposable(otherSubscription)
        let sourceSubscription = _parent._source.subscribe(self)
        return Disposables.create(sourceSubscription, otherObserver._subscription)
    }
    
}

fileprivate final class TakeUntilSinkOther<OtherElementType, O: ObserverType>: ObserverType, LockOwnerType, SynchronizedOnType {
    
    typealias E = OtherElementType
    typealias Parent = TakeUntilSink<OtherElementType, O>
    
    fileprivate let _parent: Parent
    fileprivate let _subscription = SingleAssignmentDisposable()
    
    var _lock: RecursiveLock {
        return _parent._lock
    }
    
    init(parent: Parent) {
        _parent = parent
    }
    
    func _synchronized_on(_ event: Event<OtherElementType>) {
        switch event {
        case .next:
            _parent.forwardOn(.completed)
            _parent.dispose()
        case .error(let e):
            _parent.forwardOn(.error(e))
            _parent.dispose()
        case .completed:
            _subscription.dispose()
        }
    }
    
    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }
}
