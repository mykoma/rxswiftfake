//
//  Defered.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/16.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    static func deferred<E>(_ observableFactory: @escaping () throws -> Observable<E>) -> Observable<E> {
        return Deferred(observableFactory: observableFactory)
    }
    
}

fileprivate final class Deferred<ElementType>: Producer<ElementType> {
    
    typealias Factory = () throws -> Observable<E>
    
    fileprivate let _observableFactory: Factory
    
    init(observableFactory: @escaping Factory) {
        _observableFactory = observableFactory
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = DeferredSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class DeferredSink<O: ObserverType>: Sink<O>, ObserverType {

    typealias E = O.E
    typealias Parent = Deferred<E>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }

    func on(_ event: Event<E>) {
        self.forwardOn(event)
        switch event {
        case .next:
            break
        case .completed, .error:
            dispose()
        }
    }
    
    func run() -> Disposable {
        do {
            let observable = try _parent._observableFactory()
            return observable.subscribe(self)
        } catch let e {
            forwardOn(.error(e))
            dispose()
            return Disposables.create()
        }
    }
    
}
