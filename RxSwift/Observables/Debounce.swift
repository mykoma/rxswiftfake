//
//  Debounce.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/2.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    func debounce(_ dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<E> {
        return Debounce(source: asObservable(), dueTime: dueTime, scheduler: scheduler)
    }
    
}

fileprivate final class Debounce<ElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _dueTime: RxTimeInterval
    fileprivate let _scheduler: SchedulerType
    
    init(source: Observable<ElementType>, dueTime: RxTimeInterval, scheduler: SchedulerType) {
        _source = source
        _dueTime = dueTime
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = DebounceSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class DebounceSink<O: ObserverType>: Sink<O>, ObserverType, LockOwnerType, SynchronizedOnType {
    
    typealias E = O.E
    typealias Parent = Debounce<E>
    
    fileprivate let _parent: Parent
    
    var _lock = RecursiveLock()
    
    fileprivate var _id: UInt64 = 0
    fileprivate var _value: E? = nil
    fileprivate let _cancellable = SerialDisposable()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }
    
    func run() -> Disposable {
        let subscription = _parent._source.subscribe(self)
        return Disposables.create(_cancellable, subscription)
    }

    func _synchronized_on(_ event: Event<O.E>) {
        switch event {
        case .next(let value):
            _id = _id &+ 1
            let currentId = _id
            _value = value
            
            let scheduler = _parent._scheduler
            let d = SingleAssignmentDisposable()
            _cancellable.disposable = d
            
            let subscription = scheduler.scheduleRelative(currentId,
                                                          dueTime: _parent._dueTime,
                                                          action: self.propagate)
            d.setDisposable(subscription)
        case .completed:
            if let value = _value {
                _value = nil
                forwardOn(.next(value))
            }
            forwardOn(.completed)
            dispose()
        case .error(let e):
            _value = nil
            forwardOn(.error(e))
            dispose()
        }
    }
    
    func propagate(_ currentId: UInt64) -> Disposable {
        _lock.lock(); defer { _lock.unlock() }
        if let originalValue = _value, _id == currentId {
            _value = nil
            forwardOn(.next(originalValue))
        }
        return Disposables.create()
    }
    
}
