//
//  Repeat.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/3.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    static func repeatElement(_ element: E, scheduler: ImmediateSchedulerType = CurrentThreadScheduler.instance) -> Observable<E> {
        return RepeatElement(element: element, scheduler: scheduler)
    }
    
}

fileprivate final class RepeatElement<E>: Producer<E> {
    
    fileprivate let _element: E
    fileprivate let _scheduler: ImmediateSchedulerType
    
    init(element: E, scheduler: ImmediateSchedulerType) {
        _element = element
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == E {
        let sink = RepeatElementSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class RepeatElementSink<O: ObserverType>: Sink<O> {
    
    typealias Parent = RepeatElement<O.E>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func run() -> Disposable {
        return _parent._scheduler.scheduleRecursive(_parent._element, action: { (e, recurse) in
            self.forwardOn(.next(e))
            recurse(e)
        })
    }
    
}



