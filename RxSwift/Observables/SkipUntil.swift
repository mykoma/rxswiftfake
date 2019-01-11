//
//  SkipUntil.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/11.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func skipUntil<O: ObservableType>(_ other: O) -> Observable<E> {
        return SkipUntil(source: asObservable(), other: other.asObservable())
    }
    
}

fileprivate final class SkipUntil<ElementType, OtherElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    
    fileprivate let _other: Observable<OtherElementType>
    
    init(source: Observable<ElementType>, other: Observable<OtherElementType>) {
        _source = source
        _other = other
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = SkipUntilSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class SkipUntilSink<OtherElementType, O: ObserverType>: Sink<O>, ObserverType, LockOwnerType, SynchronizedOnType {
   
    typealias E = O.E
    
    typealias Parent = SkipUntil<E, OtherElementType>
    
    fileprivate let _sourceSubscription = SingleAssignmentDisposable()
    fileprivate var _forwardsElement = false
    fileprivate let _parent: Parent
    var _lock = RecursiveLock()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func _synchronized_on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            if _forwardsElement {
                forwardOn(.next(value))
            }
        case .completed:
            if _forwardsElement {
                forwardOn(.completed)
            }
            dispose()
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        }
    }
    
    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }
    
    func run() -> Disposable {
        let otherObserver = SkipUntilSinkOther(parent: self)
        let otherSubscription = _parent._other.subscribe(otherObserver)
        let sourceSubscription = _parent._source.subscribe(self)
        _sourceSubscription.setDisposable(sourceSubscription)
        otherObserver._subscription.setDisposable(otherSubscription)
        return Disposables.create(sourceSubscription, otherSubscription)
    }
    
}

fileprivate final class SkipUntilSinkOther<OtherElementType, O: ObserverType>: ObserverType, LockOwnerType, SynchronizedOnType {

    typealias Parent = SkipUntilSink<OtherElementType, O>
    
    fileprivate let _parent: Parent
    fileprivate let _subscription = SingleAssignmentDisposable()
    
    var _lock: RecursiveLock {
        return _parent._lock
    }
    
    init(parent: Parent) {
        _parent = parent
    }
    
    func _synchronized_on(_ event: Event<E>) {
        switch event {
        case .next:
            _parent._forwardsElement = true
            _subscription.dispose()
        case .completed:
            _subscription.dispose()
        case .error(let e):
            _parent.forwardOn(.error(e))
            _parent.dispose()
        }
    }

    func on(_ event: Event<OtherElementType>) {
        synchronizedOn(event)
    }

}
