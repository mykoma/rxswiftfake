//
//  Range.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/3.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType where E: RxAbstractInteger {
    
    static func range(start: E, count: E, scheduler: ImmediateSchedulerType = CurrentThreadScheduler.instance) -> Observable<E> {
        return RangeProducer(start: start, count: count, scheduler: scheduler)
    }
    
}

fileprivate final class RangeProducer<E: RxAbstractInteger>: Producer<E> {
    
    fileprivate let _start: E
    fileprivate let _count: E
    fileprivate let _scheduler: ImmediateSchedulerType
    
    init(start: E, count: E, scheduler: ImmediateSchedulerType) {
        if count < 0 {
            rxFatalError("count can't be negative")
        }
        if start &+ (count - 1) < start {
            rxFatalError("overflow of count")
        }
        _start = start
        _count = count
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == E {
        let sink = RangeSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
}

fileprivate final class RangeSink<O: ObserverType>: Sink<O> where O.E: RxAbstractInteger {
    
    typealias Parent = RangeProducer<O.E>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func run() -> Disposable {
        return _parent._scheduler.scheduleRecursive((0 as O.E), action: { (i, recurse) in
            if i < self._parent._count {
                self.forwardOn(.next(self._parent._start + i))
                recurse(i + 1)
            } else {
                self.forwardOn(.completed)
                self.dispose()
            }
        })
    }
    
}
