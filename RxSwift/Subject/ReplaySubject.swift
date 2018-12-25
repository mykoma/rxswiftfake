//
//  ReplaySubject.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/24.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

class ReplaySubject<ElementType>:
    Observable<ElementType>,
    ObserverType,
    SubjectType,
    Cancelable {

    typealias SubjectObserverType = ReplaySubject<ElementType>
    typealias Observers = AnyObserver<ElementType>.s
    typealias DisposeKey = Observers.KeyType
    
    fileprivate let _lock = RecursiveLock()
    fileprivate var _isDisposed = false
    fileprivate var _observers = Observers()
    fileprivate var _stoppedEvent: Event<ElementType>?
    
    var isDisposed: Bool {
        return _isDisposed
    }
    
    static func create(bufferSize: Int) -> ReplaySubject<ElementType> {
        if bufferSize == 1 {
            return ReplayOne<ElementType>()
        } else {
            return ReplayMany<ElementType>(queueSize: bufferSize)
        }
    }
    
    static func createUnbouned() -> ReplaySubject<ElementType> {
        return ReplayAll<ElementType>(queueSize: 0)
    }
    
    func on(_ event: Event<ElementType>) {
        rxAbstractMethod()
    }
    
    func dispose() {
        
    }
    
    func asObserver() -> SubjectObserverType {
        return self
    }
    
}

fileprivate class ReplaySubjectBase<ElementType>:
    ReplaySubject<ElementType>,
    SynchronizedUnsubscribeType {
    
    fileprivate func trim() {
        rxAbstractMethod()
    }
    
    fileprivate func addValueToBuffer(_ element: ElementType) {
        rxAbstractMethod()
    }

    fileprivate func replayBuffer<O: ObserverType>(_ observer: O) where O.E == E {
        rxAbstractMethod()
    }
    
    override func on(_ event: Event<ElementType>) {
        dispatch(_sychronzied_on(event), event)
        
    }
    
    private func _sychronzied_on(_ event: Event<ElementType>) -> Observers {
        _lock.lock(); defer { _lock.unlock() }
        if _isDisposed || _stoppedEvent != nil {
            return Observers()
        }
        switch event {
        case .next(let value):
            addValueToBuffer(value)
            trim()
            return _observers
        case .error, .completed:
            _stoppedEvent = event
            trim()
            let observer = _observers
            _observers.removeAll()
            return observer
        }
    }
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        _lock.lock(); defer { _lock.unlock() }
        return _synchronized_subscribe(observer)
    }
    
    private func _synchronized_subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        if _isDisposed {
            observer.on(.error(RxError.disposed(object: self)))
            return Disposables.create()
        }
        let anyObserver = observer.asObserver()
        replayBuffer(anyObserver)
        if let stoppedEvent = _stoppedEvent {
            observer.on(stoppedEvent)
            return Disposables.create()
        } else {
            let key = _observers.insert(observer.on)
            return SubscriptionDisposable(owner: self, key: key)
        }
    }
    
    func synchronizedUnsubscribe(_ disposeKey: DisposeKey) {
        _lock.lock(); defer { _lock.unlock() }
        _synchronized_unsubscribe(disposeKey)
    }
    
    private func _synchronized_unsubscribe(_ disposeKey: DisposeKey) {
        if _isDisposed {
            return
        }
        _ = _observers.removeKey(disposeKey)
    }
    
    override func dispose() {
        super.dispose()
        synchronziedDispose()
    }
    
    private func synchronziedDispose() {
        _lock.lock(); defer { _lock.unlock() }
        _synchronized_dispose()
    }
    
    fileprivate func _synchronized_dispose() {
        _isDisposed = true
        _observers.removeAll()
    }
}

fileprivate final class ReplayOne<ElementType>: ReplaySubjectBase<ElementType> {
    
    private var _value: ElementType?
    
    override func trim() {
        
    }
    
    override func addValueToBuffer(_ value: ElementType) {
        _value = value
    }
    
    override func replayBuffer<O>(_ observer: O) where ElementType == O.E, O : ObserverType {
        if let value = _value {
            observer.onNext(value)
        }
    }
    
    override func _synchronized_dispose() {
        super._synchronized_dispose()
        _value = nil
    }
    
}

fileprivate class ReplayManyBase<ElementType>: ReplaySubjectBase<ElementType> {
    fileprivate var _queue: Queue<ElementType>
    
    init(queueSize: Int) {
        _queue = Queue<ElementType>(capacity: queueSize + 1)
    }
    
    override func addValueToBuffer(_ value: ElementType) {
        _queue.enqueue(value)
    }
    
    override func replayBuffer<O>(_ observer: O) where ElementType == O.E, O : ObserverType {
        for value in _queue {
            observer.onNext(value)
        }
    }
    
    override func _synchronized_dispose() {
        super._synchronized_dispose()
        _queue = Queue(capacity: 0) // ???
    }
}

fileprivate final class ReplayMany<ElementType>: ReplayManyBase<ElementType> {
    
    private var _bufferSize: Int = 0
    
    override init(queueSize: Int) {
        _bufferSize = queueSize
        super.init(queueSize: queueSize)
    }
    
    override func trim() {
        while _queue.count > _bufferSize {
            _queue.dequeue()
        }
    }
    
}

fileprivate final class ReplayAll<ElementType>: ReplayManyBase<ElementType> {
    
    override func trim() {
    }
    
}
