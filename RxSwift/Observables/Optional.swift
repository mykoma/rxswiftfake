//
//  Optional.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/2.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    static func from(optional: E?) -> Observable<E> {
        return ObservableOptional(optional: optional)
    }
    
    static func from(optional: E?, scheduler: ImmediateSchedulerType) -> Observable<E> {
        return ObservableOptionalScheduled(optional: optional, scheduler: scheduler)
    }
    
}

fileprivate final class ObservableOptional<E>: Producer<E> {
    
    fileprivate let _optional: E?
    
    init(optional: E?) {
        _optional = optional
    }
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        if let optional = _optional {
            observer.on(.next(optional))
        }
        observer.on(.completed)
        return Disposables.create()
    }
    
}

fileprivate final class ObservableOptionalScheduled<E>: Producer<E> {
    
    fileprivate let _optional: E?
    fileprivate let _scheduler: ImmediateSchedulerType
    
    init(optional: E?, scheduler: ImmediateSchedulerType) {
        _optional = optional
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == E {
        let sink = ObservableOptionalScheduledSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class ObservableOptionalScheduledSink<O: ObserverType>: Sink<O> {
    typealias E = O.E
    typealias Parent = ObservableOptionalScheduled<E>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func run() -> Disposable {
        return _parent._scheduler.schedule(_parent._optional,
                                           action:
            { (optional: E?) -> Disposable in
                if let value = optional {
                    self.forwardOn(.next(value))
                    return self._parent._scheduler.schedule((), action: { (_) -> Disposable in
                        self.forwardOn(.completed)
                        self.dispose()
                        return Disposables.create()
                    })
                } else {
                    self.forwardOn(.completed)
                    self.dispose()
                    return Disposables.create()
                }
        })
    }
}
