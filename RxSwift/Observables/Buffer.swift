//
//  Buffer.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/27.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    func buffer(timeSpan: RxTimeInterval, count: Int, scheduler: SchedulerType) -> Observable<[E]> {
        return BufferTimeCount(source: asObservable(), timeSpan: timeSpan, count: count, scheduler: scheduler)
    }
    
}

fileprivate final class BufferTimeCount<ElementType>: Producer<[ElementType]> {
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _timeSpan: RxTimeInterval
    fileprivate let _count: Int
    fileprivate let _scheduler: SchedulerType

    init(source: Observable<ElementType>, timeSpan: RxTimeInterval, count: Int, scheduler: SchedulerType) {
        _source = source
        _timeSpan = timeSpan
        _count = count
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == [ElementType] {
        let sink = BufferTimeCountSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class BufferTimeCountSink<ElementType, O: ObserverType>: Sink<O>, ObserverType, LockOwnerType, SynchronizedOnType where O.E == [ElementType] {
    
    typealias E = ElementType
    typealias Parent = BufferTimeCount<ElementType>
    
    fileprivate let _parent: Parent
    fileprivate var _buffer = [ElementType]()
    fileprivate var _windowID = 0
    
    fileprivate let _timerD = SerialDisposable()
    fileprivate let _lock = RecursiveLock()
    
    init(parent: Parent,  observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func _synchronized_on(_ event: Event<ElementType>) {
        switch event {
        case .next(let value):
            _buffer.append(value)
            if _buffer.count >= _parent._count {
                startNewWindowAndSendCurrentOne()
            }
        case .error(let e):
            _buffer = []
            forwardOn(.error(e))
            dispose()
        case .completed:
            forwardOn(.next(_buffer))
            forwardOn(.completed)
            dispose()
        }
    }
    
    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }
    
    func run() -> Disposable {
        createTimer(_windowID)
        return Disposables.create(_timerD, _parent._source.subscribe(self))
    }
    
    func startNewWindowAndSendCurrentOne() {
        _windowID = _windowID &+ 1
        let windowID = _windowID
        
        let buffer = _buffer
        _buffer = []
        forwardOn(.next(buffer))
        createTimer(windowID)
    }
    
    func createTimer(_ windowID: Int) {
        if _timerD.isDisposed { return }
        if _windowID != windowID { return }
        let nextTimer = SingleAssignmentDisposable()
        _timerD.disposable = nextTimer
        
        let disposable = _parent._scheduler.scheduleRelative(windowID, dueTime: _parent._timeSpan) { previousWindowID -> Disposable in
            self._lock.performLocked {
                if previousWindowID != self._windowID {
                    return
                }
                self.startNewWindowAndSendCurrentOne()
            }
            return Disposables.create()
        }
        nextTimer.setDisposable(disposable)
    }
    
}
