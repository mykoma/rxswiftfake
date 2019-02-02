//
//  DelaySubscription.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/2.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    func delaySubscription(_ dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<E> {
        return DelaySubscription(source: asObservable(), dueTime: dueTime, scheduler: scheduler)
    }
    
}

fileprivate final class DelaySubscription<ElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _dueTime: RxTimeInterval
    fileprivate let _scheduler: SchedulerType
    
    init(source: Observable<ElementType>, dueTime: RxTimeInterval, scheduler: SchedulerType) {
        _source = source
        _dueTime = dueTime
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = DelaySubscriptionSink(observer: observer, cancel: cancel)
        let subscription = _scheduler
            .scheduleRelative((),
                              dueTime: _dueTime)
            { _ -> Disposable in
                return self._source.subscribe(sink)
        }
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class DelaySubscriptionSink<O: ObserverType>: Sink<O>, ObserverType {
    
    typealias E = O.E
    
    func on(_ event: Event<E>) {
        forwardOn(event)
        if event.isStopEvent {
            dispose()
        }
    }

}
