//
//  Sequence.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/3.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    static func of(_ elements: E ..., scheduler: ImmediateSchedulerType = CurrentThreadScheduler.instance) -> Observable<E> {
        return ObservableSequence(elements: elements, scheduler: scheduler)
    }
    
}

extension ObservableType {
    
    static func from(_ array: [E], scheduler: ImmediateSchedulerType = CurrentThreadScheduler.instance) -> Observable<E> {
        return ObservableSequence(elements: array, scheduler: scheduler)
    }
    
    static func from<S: Sequence>(_ sequence: S, scheduler: ImmediateSchedulerType = CurrentThreadScheduler.instance) -> Observable<E> where S.Iterator.Element == E {
        return ObservableSequence(elements: sequence, scheduler: scheduler)
    }
    
}

fileprivate final class ObservableSequence<S: Sequence>: Producer<S.Iterator.Element> {
    
    fileprivate let _elements: S
    fileprivate let _scheduler: ImmediateSchedulerType
    
    init(elements: S, scheduler: ImmediateSchedulerType) {
        _elements = elements
        _scheduler = scheduler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == S.Iterator.Element {
        let sink = ObservableSequenceSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class ObservableSequenceSink<S: Sequence, O: ObserverType>: Sink<O> where S.Iterator.Element == O.E {
    
    typealias Parent = ObservableSequence<S>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
 
    func run() -> Disposable {
        return _parent._scheduler.scheduleRecursive(_parent._elements.makeIterator(), action: { (iterator, recurse) in
            var mutableIterator = iterator
            if let value = mutableIterator.next() {
                self.forwardOn(.next(value))
                recurse(mutableIterator)
            } else {
                self.forwardOn(.completed)
                self.dispose()
            }
        })
    }
}
