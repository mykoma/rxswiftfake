//
//  Just.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    static func just(_ element: E) -> Observable<E> {
        return Just(element: element)
    }
    
}

extension ObservableType {
    
    static func just(_ element: E, scheduler: ImmediateSchedulerType) -> Observable<E> {
        return JustScheduled(element: element, scheduler: scheduler)
    }
    
}

fileprivate final class Just<ElementType>: Producer<ElementType> {
    
    fileprivate let _element: ElementType
    
    init(element: ElementType) {
        _element = element
    }
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        observer.onNext(_element)
        observer.onCompleted()
        return Disposables.create()
    }
    
}

fileprivate final class JustScheduled<ElementType>: Producer<ElementType> {
    
    fileprivate let _element: ElementType
    fileprivate let _scheduler: ImmediateSchedulerType
    
    init(element: ElementType, scheduler: ImmediateSchedulerType) {
        _element = element
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = JustScheduledSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class JustScheduledSink<ElementType, O: ObserverType>: Sink<O> where ElementType == O.E {
    
    typealias E = ElementType
    typealias Parent = JustScheduled<ElementType>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func run() -> Disposable {
        let scheduler = _parent._scheduler
        return scheduler.schedule(_parent._element, action: { (element) -> Disposable in
            self.forwardOn(.next(element))
            return scheduler.schedule((), action: { (_) -> Disposable in
                self.forwardOn(.completed)
                self.dispose()
                return Disposables.create()
            })
        })
    }
    
}
