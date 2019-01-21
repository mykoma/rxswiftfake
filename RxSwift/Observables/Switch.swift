//
//  Switch.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/21.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType where E: ObservableConvertibleType {
    
    func switchLatest() -> Observable<E.E> {
        return Switch(source: asObservable())
    }
    
}

fileprivate final class Switch<SourceObservable: ObservableConvertibleType>: Producer<SourceObservable.E> {
    
    fileprivate let _source: Observable<SourceObservable>
    
    init(source: Observable<SourceObservable>) {
        _source = source
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == SourceObservable.E {
        let sink = SwitchSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class SwitchSink<SourceObservable: ObservableConvertibleType, O: ObserverType>: Sink<O>, ObserverType where SourceObservable.E == O.E {
    
    typealias Parent = Switch<SourceObservable>
    
    fileprivate let _parent: Parent
    fileprivate let _subscription = SingleAssignmentDisposable()
    fileprivate let _innerSubscription = SerialDisposable()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<SourceObservable>) {
        switch event {
        case .next(let value):
            let sinkIter = SwitchSinkIter(parent: self)
            let subscription = value.asObservable().subscribe(sinkIter)
            _innerSubscription.disposable = subscription
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        case .completed:
            forwardOn(.completed)
            dispose()
        }
    }
    
    func run() -> Disposable {
        let subscrption = _parent._source.subscribe(self)
        _subscription.setDisposable(subscrption)
        return Disposables.create(_subscription, _innerSubscription)
    }
    
}

fileprivate final class SwitchSinkIter<SourceObservable: ObservableConvertibleType, O: ObserverType>: ObserverType where SourceObservable.E == O.E {

    typealias Parent = SwitchSink<SourceObservable, O>

    fileprivate let _parent: Parent

    init(parent: Parent) {
        _parent = parent
    }

    func on(_ event: Event<O.E>) {
        _parent.forwardOn(event)
        switch event {
        case .next:
            break
        case .completed, .error:
            _parent.dispose()
        }
    }

}
