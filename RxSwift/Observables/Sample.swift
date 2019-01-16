//
//  Sample.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/16.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func sample<O: ObservableType>(_ sampler: O) -> Observable<E> {
        return Sample(source: asObservable(), sampler: sampler.asObservable())
    }
    
}

fileprivate final class Sample<ElementType, SampleElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _sampler: Observable<SampleElementType>

    init(source: Observable<ElementType>, sampler: Observable<SampleElementType>) {
        _source = source
        _sampler = sampler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = SampleSequenceSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class SampleSequenceSink<SampleElementType, O: ObserverType>:
    Sink<O>,
    ObserverType,
    LockOwnerType,
    SynchronizedOnType {
    
    typealias E = O.E
    typealias Parent = Sample<E, SampleElementType>
    
    fileprivate var _element: E? = nil
    fileprivate var _atEnd = false
    fileprivate var _lock = RecursiveLock()
    fileprivate let _parent: Parent
    fileprivate let _sourceSubscription = SingleAssignmentDisposable()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }
    
    func _synchronized_on(_ event: Event<O.E>) {
        switch event {
        case .next(let value):
            _element = value
        case .completed:
            _atEnd = true
            _sourceSubscription.dispose()
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        }
    }
    
    func run() -> Disposable {
        _sourceSubscription.setDisposable(_parent._source.subscribe(self))
        let samplerSubscription = _parent._sampler.subscribe(SamplerSink(parent: self))
        
        return Disposables.create(_sourceSubscription, samplerSubscription)
    }

}

fileprivate final class SamplerSink<SampleElementType, O: ObserverType>:
    ObserverType,
    LockOwnerType,
    SynchronizedOnType {
    
    typealias Parent = SampleSequenceSink<SampleElementType, O>
    
    fileprivate let _parent: Parent
    
    fileprivate var _lock: RecursiveLock {
        return _parent._lock
    }
    
    init(parent: Parent) {
        _parent = parent
    }
    
    func on(_ event: Event<SampleElementType>) {
        synchronizedOn(event)
    }

    func _synchronized_on(_ event: Event<SampleElementType>) {
        switch event {
        case .next, .completed:
            if let element = _parent._element {
                _parent._element = nil
                _parent.forwardOn(.next(element))
            }
            if _parent._atEnd {
                _parent.forwardOn(.completed)
                _parent.dispose()
            }
        case .error(let e):
            _parent.forwardOn(.error(e))
            _parent.dispose()
        }
    }
    
}
