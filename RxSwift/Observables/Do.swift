//
//  Do.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/22.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func `do`(onNext: ((E) throws -> Void)? = nil,
              onError: ((Error) throws -> Void)? = nil,
              onCompleted: (() throws -> Void)? = nil,
              onSubscribe: (() -> Void)? = nil,
              onSubscribed: (() -> Void)? = nil,
              onDispose: (() -> Void)? = nil) -> Observable<E> {
        return Do(source: asObservable(), eventHandler: { (event) in
            switch event {
            case .next(let value):
                try onNext?(value)
            case .completed:
                try onCompleted?()
            case .error(let e):
                try onError?(e)
            }
        }, onSubscribe: onSubscribe, onSubscribed: onSubscribed, onDispose: onDispose)
    }
    
}

fileprivate final class Do<ElementType>: Producer<ElementType> {
    
    typealias EventHandler = (Event<ElementType>) throws -> Void
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _eventHandler: EventHandler
    fileprivate let _onSubscribe: (() -> Void)?
    fileprivate let _onSubscribed: (() -> Void)?
    fileprivate let _onDispose: (() -> Void)?
    
    init(source: Observable<ElementType>,
         eventHandler: @escaping EventHandler,
         onSubscribe: (() -> Void)?,
         onSubscribed: (() -> Void)?,
         onDispose: (() -> Void)?) {
        _source = source
        _eventHandler = eventHandler
        _onSubscribe = onSubscribe
        _onSubscribed = onSubscribed
        _onDispose = onDispose
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        _onSubscribe?()
        let sink = DoSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        _onSubscribed?()
        let onDispose = _onDispose
        return (sink: sink, subscription: Disposables.create {
            subscription.dispose()
            onDispose?()
        })
    }
    
}

fileprivate final class DoSink<ElementType, O: ObserverType>: Sink<O>, ObserverType where ElementType == O.E {
    
    typealias E = O.E
    typealias Parent = Do<ElementType>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        do {
            try _parent._eventHandler(event)
            forwardOn(event)
            if event.isStopEvent {
                dispose()
            }
        } catch let e {
            forwardOn(.error(e))
            dispose()
        }
    }
    
}
