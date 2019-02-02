//
//  Delay.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/2.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    func delay(_ dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<E> {
        return Delay(source: asObservable(), dueTime: dueTime, scheduler: scheduler)
    }
    
}

fileprivate final class Delay<ElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _dueTime: RxTimeInterval
    fileprivate let _scheduler: SchedulerType
    
    init(source: Observable<ElementType>, dueTime: RxTimeInterval, scheduler: SchedulerType) {
        _source = source
        _dueTime = dueTime
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = DelaySink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
}

fileprivate final class DelaySink<O: ObserverType>: Sink<O>, ObserverType {
    
    typealias E = O.E
    typealias Parent = Delay<E>
    
    fileprivate var _active = false
    fileprivate var _running = false
    fileprivate var _errorEvent: Event<E>? = nil
    fileprivate var _queue = Queue<(eventTime: RxTime, event: Event<E>)>(capacity: 0)
    fileprivate let _lock = RecursiveLock()
    fileprivate let _parent: Parent
    fileprivate let _sourceSubscription = SingleAssignmentDisposable()
    fileprivate let _cancelable = SerialDisposable()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        if event.isStopEvent {
            _sourceSubscription.dispose()
        }
        
        switch event {
        case .error:
            _lock.lock()
            let shouldSendImmediately = !_running
            _queue = Queue<(eventTime: RxTime, event: Event<E>)>(capacity: 0)
            _errorEvent = event
            _lock.unlock()
            
            if shouldSendImmediately {
                forwardOn(event)
                dispose()
            }
        default:
            _lock.lock()
            let shouldSchedule = !_active
            _active = true
            _queue.enqueue((_parent._scheduler.now, event))
            _lock.unlock()
            
            if shouldSchedule {
                _cancelable.disposable = _parent
                    ._scheduler
                    .scheduleRecursive((),
                                       dueTime: _parent._dueTime,
                                       action: self.drainQueue)
            }
        }
    }
    
    func run() -> Disposable {
        _sourceSubscription.setDisposable(_parent._source.subscribe(self))
        return Disposables.create(_sourceSubscription, _cancelable)
    }
    
    func drainQueue(state: (), scheduler: AnyRecursiveScheduler<()>) {
        _lock.lock()
        let hasFailed = _errorEvent != nil
        if !hasFailed {
            _running = true
        }
        _lock.unlock()
        
        if hasFailed { return }
        
        var ranAtLeastOnce = false
        
        while true {
            _lock.lock()
            let errorEvent = _errorEvent
            let eventToForwardImmediately = ranAtLeastOnce ? nil : _queue.dequeue()?.event
            let nextEventToScheduleOriginalTime: RxTime? = ranAtLeastOnce && !_queue.isEmpty ? _queue.peek().eventTime : nil
            if _errorEvent == nil {
                if let _ = eventToForwardImmediately {
                } else if let _ = nextEventToScheduleOriginalTime {
                    _running = false
                } else {
                    _running = false
                    _active = false
                }
            }
            _lock.unlock()
            
            if let errorEvent = errorEvent {
                self.forwardOn(errorEvent)
                self.dispose()
                return
            }
            else {
                if let eventToForwardImmediately = eventToForwardImmediately {
                    ranAtLeastOnce = true
                    self.forwardOn(eventToForwardImmediately)
                    if case .completed = eventToForwardImmediately {
                        self.dispose()
                        return
                    }
                }
                else if let nextEventToScheduleOriginalTime = nextEventToScheduleOriginalTime {
                    let elapsedTime = _parent._scheduler.now.timeIntervalSince(nextEventToScheduleOriginalTime)
                    let interval = _parent._dueTime - elapsedTime
                    let normalizedInterval = interval < 0.0 ? 0.0 : interval
                    scheduler.schedule((), dueTime: normalizedInterval)
                    return
                }
                else {
                    return
                }
            }
        }
    }
    
}
