//
//  BehaviorSubject.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

final class BehaviorSubject<ElementType>:
    Observable<ElementType>,
    SubjectType,
    SynchronizedUnsubscribeType,
    ObserverType,
    Cancelable { // RxSwift的代码是Disposable
    
    typealias E = ElementType
    
    // 一个subject可能会有多个订阅者，所以需要一个容器来装载这些订阅者，这里就定义了Bag的存在意义
    typealias Observers = AnyObserver<E>.s // Bag<(Event<E>) -> Void>
    typealias DisposeKey = Observers.KeyType
    
    private var _element: E
    private var _isDisposed = false
    private var _observers = Observers() // Bag<(Event<E>) -> Void>
    private var _stoppedEvent: Event<E>?
    
    let _lock = RecursiveLock()
    
    init(_ element: E) {
        _element = element
        super.init()
    }
    
    func asObserver() -> BehaviorSubject<E> {
        return self
    }
    
    func on(_ event: Event<E>) {
        dispatch(_synchronized_on(event), event)
    }
    
    func _synchronized_on(_ event: Event<E>) -> Observers { // Bag<(Event<E>) -> Void>
        defer {
            _lock.unlock()
        }
        _lock.lock()
        // 如果已经dispose了，则生成一个临时的 Bag 去承担触发事件容器
        //（结果是不会有任何事情发生，因为在临时的 Bag 中没有任何的订阅者）。
        if _stoppedEvent != nil || _isDisposed {
            return Observers() // Bag<(Event<E>) -> Void>
        }
        switch event {
        case .next(let element):
            _element = element
        case .error, .completed:
            _stoppedEvent = event
        }
        return _observers // Bag<(Event<E>) -> Void>
    }
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        defer {
            _lock.unlock()
        }
        _lock.lock()
        let disposable = _synchronized_subscribe(observer)
        return disposable
    }
    
    func _synchronized_subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        if _isDisposed {
            observer.on(.error(RxError.disposed(object: self)))
            return Disposables.create()
        }
        
        if let stoppedEvent = _stoppedEvent {
            observer.on(stoppedEvent)
            return Disposables.create()
        }
        
        let key = _observers.insert(observer.on)
        observer.on(.next(_element))
        
        return SubscriptionDisposable(owner: self, key: key)
    }
    
    func synchronizedUnsubscribe(_ disposeKey: DisposeKey) {
        defer {
            _lock.unlock()
        }
        _lock.lock()
        _synchronized_unsubscribe(disposeKey)
    }
    
    func _synchronized_unsubscribe(_ disposeKey: DisposeKey) {
        if _isDisposed {
            return
        }
        _ = _observers.removeKey(disposeKey)
    }
    
    var isDisposed: Bool {
        return _isDisposed
    }
    
    func dispose() {
        defer {
            _lock.unlock()
        }
        _lock.lock()
        _isDisposed = true
        _observers.removeAll() // Bag<(Event<E>) -> Void>
        _stoppedEvent = nil
    }
    
}
