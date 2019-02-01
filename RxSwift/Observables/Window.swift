//
//  Window.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/1.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    func window(timeSpan: RxTimeInterval, count: Int, scheduler: SchedulerType) -> Observable<Observable<E>> {
        return WindowTimeCount(source: asObservable(), timeSpan: timeSpan, count: count, scheduler: scheduler)
    }
    
}

fileprivate final class WindowTimeCount<ElementType>: Producer<Observable<ElementType>> {
    
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
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == Observable<ElementType> {
        let sink = WindowTimeCountSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class WindowTimeCountSink<ElementType, O: ObserverType>: Sink<O>, ObserverType, LockOwnerType, SynchronizedOnType where O.E == Observable<ElementType> {
    
    typealias E = ElementType
    typealias Parent = WindowTimeCount<ElementType>
    
    var _lock = RecursiveLock()
    
    fileprivate var _windowId = 0
    fileprivate var _count = 0
    fileprivate var _subject = PublishSubject<ElementType>()
    fileprivate let _parent: Parent
    fileprivate let _timerD = SerialDisposable()
    fileprivate let _refCountDisposable: RefCountDisposable
    fileprivate let _groupDisposable = CompositeDisposable()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        let _ = _groupDisposable.insert(_timerD)
        _refCountDisposable = RefCountDisposable(disposable: _groupDisposable)
        super.init(observer: observer, cancel: cancel)
    }

    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }
    
    func _synchronized_on(_ event: Event<E>) {
        var newWindow = false
        var newId = 0
        
        switch event {
        case .next(let element):
            _subject.on(.next(element))
            do {
                let _ = try incrementChecked(&_count)
            } catch let e {
                _subject.on(.error(e))
                dispose()
            }
            
            if _count == _parent._count {
                newWindow = true
                _count = 0
                _windowId += 1
                newId = _windowId
                startNewWindowAndCompleteCurrentOne()
            }
        case .error(let e):
            _subject.on(event)
            forwardOn(.error(e))
            dispose()
        case .completed:
            _subject.onCompleted()
            forwardOn(.completed)
            dispose()
        }
        
        if newWindow {
            createTimer(newId)
        }
    }
    
    func run() -> Disposable {
        forwardOn(.next(AddRef(source: _subject, refCount: _refCountDisposable)))
        createTimer(_windowId)
        let _ = _groupDisposable.insert(_parent._source.subscribe(self))
        return _refCountDisposable
    }
    
    func createTimer(_ windowId: Int) {
        if _timerD.isDisposed { return }
        if _windowId != windowId { return }
        let nextTimer = SingleAssignmentDisposable()
        _timerD.disposable = nextTimer
        
        let scheduledRelative = _parent
            ._scheduler
            .scheduleRelative(windowId,
                              dueTime: _parent._timeSpan)
            { previousWindowId -> Disposable in
                var newId = 0
                self._lock.performLocked {
                    if previousWindowId != self._windowId { return }
                    self._count = 0
                    self._windowId = self._windowId &+ 1
                    newId = self._windowId
                    self.startNewWindowAndCompleteCurrentOne()
                }
                self.createTimer(newId)
                return Disposables.create()
        }
        nextTimer.setDisposable(scheduledRelative)
    }
    
    func startNewWindowAndCompleteCurrentOne() {
        _subject.onCompleted()
        _subject = PublishSubject<ElementType>()
        forwardOn(.next(AddRef(source: _subject, refCount: _refCountDisposable)))
    }

}
