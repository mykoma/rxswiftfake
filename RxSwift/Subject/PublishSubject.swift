//
//  PublishSubject.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/24.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

final class PublishSubject<ElementType>:
    Observable<ElementType>,
    Cancelable,
    ObserverType,
    SynchronizedUnsubscribeType, SubjectType {
    
    typealias Observers = AnyObserver<ElementType>.s
    typealias DisposeKey = Observers.KeyType

    private var _lock = RecursiveLock()
    private var _observers = Observers()
    private var _stoppedEvent: Event<ElementType>?
    private var _isDisposed: Bool = false
    var isDisposed: Bool {
        return _isDisposed
    }
    
    func on(_ event: Event<ElementType>) {
        dispatch(_synchronized_on(event), event)
    }
    
    func _synchronized_on(_ event: Event<ElementType>) -> Observers {
        _lock.lock(); defer { _lock.unlock() }
        switch event {
        case .next:
            if _stoppedEvent != nil || _isDisposed {
                return Observers()
            }
            return _observers
        case .error,.completed:
            if _stoppedEvent == nil {
                _stoppedEvent = event
                _observers.removeAll()
                return _observers
            }
            return Observers()
        }
    }
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        _lock.lock(); defer { _lock.unlock() }
        return _synchronized_subscribe(observer)
    }
    
    func _synchronized_subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        if let stoppedEvent = _stoppedEvent {
            observer.on(stoppedEvent)
            return Disposables.create()
        }
        
        if _isDisposed {
            observer.on(.error(RxError.disposed(object: self)))
            return Disposables.create()
        }
        
        let key = _observers.insert(observer.on)
        return SubscriptionDisposable(owner: self, key: key)
    }
    
    func dispose() {
        _lock.lock(); defer { _lock.unlock() }
        _synchronized_dispose()
    }
    
    func _synchronized_dispose() {
        _isDisposed = true
        _observers.removeAll()
        _stoppedEvent = nil
    }
    
    func synchronizedUnsubscribe(_ disposeKey: DisposeKey) {
        _lock.lock(); defer { _lock.unlock() }
        _synchronizedUnsubscribe(disposeKey)
    }
    
    func _synchronizedUnsubscribe(_ disposeKey: DisposeKey) {
        _ = _observers.removeKey(disposeKey)
    }
    
    func asObserver() -> PublishSubject<ElementType> {
        return self
    }
    
}
