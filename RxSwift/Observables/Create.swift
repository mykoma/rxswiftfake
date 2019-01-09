//
//  Create.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/9.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    static func create(_ subscribe: @escaping (AnyObserver<E>) -> Disposable) -> Observable<E> {
        return AnonymousObservable(subscribeHandler: subscribe)
    }
    
}

final fileprivate class AnonymousObservable<ElementType>: Producer<ElementType> {
    
    typealias SubscribeHandler = (AnyObserver<ElementType>) -> Disposable
    
    let _subscribeHandler: SubscribeHandler
    
    init(subscribeHandler: @escaping SubscribeHandler) {
        _subscribeHandler = subscribeHandler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = AnonymousObservableSink(observer: observer, cancel: cancel)
        let subscription = sink.run(self)
        return (sink: sink, subscription: subscription)
    }
    
}

final fileprivate class AnonymousObservableSink<O: ObserverType>: Sink<O>, ObserverType {

    typealias E = O.E
    typealias Parent = AnonymousObservable<E>
    
    private var _isStopped = AtomicInt(0)
    
    func on(_ event: Event<E>) {
        switch event {
        case .next:
            if _isStopped.load() == 1 {
                return
            }
            forwardOn(event)
        case .error, .completed:
            if _isStopped.fetchOr(1) == 0 {
                forwardOn(event)
                dispose()
            }
        }
    }
    
    func run(_ parent: Parent) -> Disposable {
        return parent._subscribeHandler(self.asObserver())
    }
    
}
