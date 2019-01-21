//
//  Using.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/21.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    static func using<Resource: Disposable>(_ resourceFactory: @escaping () throws -> Resource,
                                            observableFactory: @escaping (Resource) throws -> Observable<E>) -> Observable<E> {
        return Using(resourceFactory: resourceFactory, observableFactory: observableFactory)
    }
    
}

fileprivate final class Using<ElementType, Resource: Disposable>: Producer<ElementType> {
    
    typealias ResourceFactory = () throws -> Resource
    typealias ObservableFactory = (Resource) throws -> Observable<ElementType>
    
    fileprivate let _resourceFactory: ResourceFactory
    fileprivate let _observableFactory: ObservableFactory
    
    init(resourceFactory: @escaping ResourceFactory, observableFactory: @escaping ObservableFactory) {
        _resourceFactory = resourceFactory
        _observableFactory = observableFactory
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = UsingSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class UsingSink<ElementType, Resource: Disposable, O: ObserverType>: Sink<O>, ObserverType where ElementType == O.E {
    
    typealias E = O.E
    
    typealias Parent = Using<ElementType, Resource>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            forwardOn(.next(value))
        case .completed, .error:
            forwardOn(event)
            dispose()
        }
    }
    
    func run() -> Disposable {
        var disposable = Disposables.create()
        do {
            let resource = try _parent._resourceFactory()
            disposable = resource
            let source = try _parent._observableFactory(resource)
            return Disposables.create(source.subscribe(self), disposable)
        } catch let e {
            return Disposables.create(
                Observable.error(e).subscribe(self),
                disposable
            )
        }
    }

}
