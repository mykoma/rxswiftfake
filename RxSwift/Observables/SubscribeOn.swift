//
//  SubscribeOn.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/24.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func subscribeOn(_ scheduler: ImmediateSchedulerType) -> Observable<E> {
        return SubscribeOn(source: asObservable(), scheduler: scheduler)
    }
    
}

fileprivate final class SubscribeOn<ElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _scheduler: ImmediateSchedulerType
    
    init(source: Observable<ElementType>, scheduler: ImmediateSchedulerType) {
        _source = source
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = SubscribeOnSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class SubscribeOnSink<ElementType, O: ObserverType>: Sink<O>, ObserverType where ElementType == O.E {
    
    typealias E = O.E
    typealias Parent = SubscribeOn<ElementType>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        forwardOn(event)
        
        if event.isStopEvent {
            dispose()
        }
    }
    
    func run() -> Disposable {
        let disposeEverything = SerialDisposable()
        let cancelSchedule = SingleAssignmentDisposable()
        disposeEverything.disposable = cancelSchedule
        
        let disposeSchedule = _parent._scheduler.schedule(()) { (_) -> Disposable in
            let subscription = self._parent._source.subscribe(self)
            disposeEverything.disposable = ScheduledDisposable(scheduler: self._parent._scheduler, disposable: subscription)
            return Disposables.create()
        }
        
        cancelSchedule.setDisposable(disposeSchedule)
        
        return disposeEverything
    }
    
}
