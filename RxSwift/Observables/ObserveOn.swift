//
//  ObserveOn.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/25.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func observeOn(_ scheduler: ImmediateSchedulerType) -> Observable<E> {
        if let scheduler = scheduler as? SerialDispatchQueueScheduler {
            return ObserveOnSerialDispatchQueue(source: asObservable(), scheduler: scheduler)
        } else {
            return ObserveOn(source: asObservable(), scheduler: scheduler)
        }
    }
    
}

fileprivate final class ObserveOn<ElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _scheduler: ImmediateSchedulerType
    
    init(source: Observable<ElementType>, scheduler: ImmediateSchedulerType) {
        _source = source
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = ObserveOnSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

enum ObserveOnState: Int32 {
    
    case stopped = 0
    
    case running = 1
    
}

fileprivate final class ObserveOnSink<ElementType, O: ObserverType>: ObserverBase<O.E> where ElementType == O.E {
    
    typealias E = O.E
    typealias Parent = ObserveOn<ElementType>
    
    fileprivate var _lock = SpinLock()
    fileprivate var _state = ObserveOnState.stopped
    fileprivate var _queue = Queue<Event<E>>(capacity: 10)
    
    fileprivate let _parent: Parent
    fileprivate let _observer: O
    fileprivate let _cancel: Cancelable
    fileprivate let _scheduleDisposable = SerialDisposable()

    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        _observer = observer
        _cancel = cancel
    }
    
    override func onCore(_ event:Event<E>) {
        let shouldStart = self._lock.calculateLocked { () -> Bool in
            self._queue.enqueue(event)
            switch self._state {
            case .stopped:
                self._state = .running
                return true
            case .running:
                return false
            }
        }
        if shouldStart {
            _scheduleDisposable.disposable = self._parent._scheduler.scheduleRecursive((), action: self.run)
        }
    }
    
    func run(_ state: (), _ recurse: (()) -> ()) {
        let nextEvent = self._lock.calculateLocked { () -> Event<E>? in
            if !self._queue.isEmpty {
                return self._queue.dequeue()
            } else {
                self._state = .stopped
                return nil
            }
        }
        if let event = nextEvent, !_cancel.isDisposed {
            self._observer.on(event)
            if event.isStopEvent {
                dispose()
            }
        } else {
            return
        }
        
        let shouldContinue = _shouldContinue_synchronized()
        if shouldContinue {
            recurse(())
        }
    }
    
    func _shouldContinue_synchronized() -> Bool {
        return self._lock.calculateLocked { () -> Bool in
            if !self._queue.isEmpty {
                return true
            } else {
                self._state = .stopped
                return false
            }
        }
    }
    
    override func dispose() {
        super.dispose()
        _cancel.dispose()
        _scheduleDisposable.dispose()
    }
    
}

fileprivate final class ObserveOnSerialDispatchQueue<ElementType>: Producer<ElementType> {

    fileprivate let _source: Observable<ElementType>
    fileprivate let _scheduler: SerialDispatchQueueScheduler

    init(source: Observable<ElementType>, scheduler: SerialDispatchQueueScheduler) {
        _source = source
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = ObserveOnSerialDispatchQueueSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class ObserveOnSerialDispatchQueueSink<O: ObserverType>: ObserverBase<O.E> {
    
    typealias E = O.E
    typealias Parent = ObserveOnSerialDispatchQueue<E>
    
    fileprivate let _parent: Parent
    fileprivate let _observer: O
    fileprivate let _cancel: Cancelable

    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        _observer = observer
        _cancel = cancel
        super.init()
    }
    
    override func onCore(_ event:Event<E>) {
        let _ = self._parent._scheduler.schedule((event), action: self.run)
    }
    
    func run(event: Event<E>) -> Disposable {
        guard !self._cancel.isDisposed else { return Disposables.create() }
        self._observer.on(event)
        return Disposables.create()
    }
    
    override func dispose() {
        super.dispose()
        
        _cancel.dispose()
    }
}
