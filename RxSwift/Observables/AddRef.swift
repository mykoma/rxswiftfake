//
//  AddRef.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/1.
//  Copyright © 2019 goluk. All rights reserved.
//

final class AddRefSink<O: ObserverType>: Sink<O>, ObserverType {
    
    typealias E = O.E
    
    func on(_ event: Event<E>) {
        forwardOn(event)
        switch event {
        case .completed, .error:
            dispose()
        default: break
        }
    }
    
}

final class AddRef<ElementType>: Producer<ElementType> {
    
    private let _source: Observable<ElementType>
    private let _refCount: RefCountDisposable
    
    init(source: Observable<ElementType>, refCount: RefCountDisposable) {
        _source = source
        _refCount = refCount
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let releaseDisposable = _refCount.retain()
        let sink = AddRefSink(observer: observer, cancel: cancel)
        let subscription = Disposables.create(releaseDisposable, _source.subscribe(sink))
        return (sink: sink, subscription: subscription)
    }
}
