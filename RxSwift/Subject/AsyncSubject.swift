//
//  AsyncSubject.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/24.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

final class AsyncSubject<ElementType>:
    Observable<ElementType>,
    ObserverType,
    SubjectType,
    SynchronizedUnsubscribeType {
    
    typealias SubjectObserverType = AsyncSubject<ElementType>
    typealias Observers = AnyObserver<ElementType>.s
    typealias DisposeKey = Observers.KeyType
    
    private var _lock = RecursiveLock()
    private var _lastElement: ElementType?
    private var _stoppedEvent: Event<ElementType>?
    private var _observers = Observers()

    func on(_ event: Event<ElementType>) {
        _lock.lock(); defer { _lock.unlock() }
        let (observers, event) = _synchronized_on(event)
        switch event {
        case .next:
            dispatch(observers, event)
            dispatch(observers, .completed)
        case .error:
            dispatch(observers, event)
        case .completed:
            dispatch(observers, event)
        }
    }
    
    func _synchronized_on(_ event: Event<ElementType>) -> (Observers, Event<E>) {
        _lock.lock(); defer { _lock.unlock() }
        
        if _stoppedEvent != nil {
            return (Observers(), .completed)
        }
        
        switch event {
        case .next(let element):
            _lastElement = element
            return (Observers(), .completed)
        case .error:
            _stoppedEvent = event
            let observers = _observers // struct copy -- value copy
            _observers.removeAll()
            return (observers, event)
        case .completed:
            let observers = _observers
            _observers.removeAll()
            
            if let lastElement = _lastElement {
                _stoppedEvent = .next(lastElement)
                return (observers, .next(lastElement))
            } else {
                _stoppedEvent = event
                return (observers, .completed)
            }
        }
    }
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        _lock.lock(); defer { _lock.unlock() }
        return _synchronized_subscribe(observer)
    }
    
    func _synchronized_subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        if let stoppedEvent = _stoppedEvent {
            switch stoppedEvent {
            case .next:
                observer.on(stoppedEvent)
                observer.on(.completed)
            case .error:
                observer.on(stoppedEvent)
            case .completed:
                observer.on(stoppedEvent)
            }
            return Disposables.create()
        }
        
        let key = _observers.insert(observer.on)
        return SubscriptionDisposable(owner: self, key: key)
    }
    
    func synchronizedUnsubscribe(_ disposeKey: DisposeKey) {
        _lock.lock(); defer { _lock.unlock() }
        _synchronized_unsubscribe(disposeKey)
    }
    
    func _synchronized_unsubscribe(_ disposeKey: DisposeKey) {
        _ = _observers.removeKey(disposeKey)
    }
    
    func asObserver() -> SubjectObserverType {
        return self
    }
    
}
