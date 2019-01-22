//
//  SwitchIfEmpty.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/22.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func ifEmpty(switchTo other: Observable<E>) -> Observable<E> {
        return SwitchIfEmpty(source: asObservable(), ifEmpty: other)
    }
    
}

fileprivate final class SwitchIfEmpty<SourceType>: Producer<SourceType> {
    
    fileprivate let _source: Observable<SourceType>
    fileprivate let _ifEmpty: Observable<SourceType>
    
    init(source: Observable<SourceType>, ifEmpty: Observable<SourceType>) {
        _source = source
        _ifEmpty = ifEmpty
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == SourceType {
        let sink = SwitchIfEmptySink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class SwitchIfEmptySink<SourceType, O: ObserverType>: Sink<O>, ObserverType where SourceType == O.E {
    
    typealias E = O.E
    typealias Parent = SwitchIfEmpty<SourceType>
    
    fileprivate let _parent: Parent
    fileprivate let _lock = RecursiveLock()
    fileprivate var _isEmpty = true
    fileprivate let _ifEmptySubscription = SingleAssignmentDisposable()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            _isEmpty = false
            forwardOn(.next(value))
        case .completed:
            if _isEmpty {
                let emptyOther = SwitchIfEmptyOther(parent: self)
                let subscription = _parent._ifEmpty.subscribe(emptyOther)
                _ifEmptySubscription.setDisposable(subscription)
                return
            }
            forwardOn(.completed)
            dispose()
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        }
    }
    
    func run() -> Disposable {
        let subscription = _parent._source.subscribe(self)
        return Disposables.create(subscription, _ifEmptySubscription)
    }
    
}

fileprivate final class SwitchIfEmptyOther<SourceType, O: ObserverType>: ObserverType, LockOwnerType, SynchronizedOnType where SourceType == O.E {
    
    typealias Parent = SwitchIfEmptySink<SourceType, O>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent) {
        _parent = parent
    }
    
    var _lock: RecursiveLock {
        return _parent._lock
    }
    
    func _synchronized_on(_ event: Event<SourceType>) {
        synchronizedOn(event)
    }
    
    func on(_ event: Event<SourceType>) {
        _parent.forwardOn(event)
        switch event {
        case .next: break
        case .completed, .error: _parent.dispose()
        }
    }
    
}
