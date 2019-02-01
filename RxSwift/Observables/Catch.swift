//
//  Catch.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func catchError(_ handler: @escaping (Error) throws -> Observable<E>) -> Observable<E> {
        return Catch(source: asObservable(), handler: handler)
    }
    
    func catchErrorJustReturn(_ element: E) -> Observable<E> {
        return Catch(source: asObservable(), handler: { _ in return Observable<E>.just(element) })
    }
    
}

extension ObservableType {
    
    static func catchError<S: Sequence>(_ sequence: S) -> Observable<E> where S.Iterator.Element == Observable<E> {
        return CatchSequence(source: sequence)
    }
    
}

extension ObservableType {
    
    func retry() -> Observable<E> {
        return CatchSequence(source: InfiniteSequence(repeatedValue: asObservable()))
    }
    
    func retry(_ maxAttemptCount: Int) -> Observable<E> {
        return CatchSequence(source: repeatElement(asObservable(), count: maxAttemptCount))
    }

}

fileprivate final class Catch<ElementType>: Producer<ElementType> {
    
    typealias Handler = (Error) throws -> Observable<ElementType>
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _handler: Handler
    
    init(source: Observable<ElementType>, handler: @escaping Handler) {
        _source = source
        _handler = handler
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = CatchSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class CatchSink<ElementType, O: ObserverType>: Sink<O>, ObserverType where ElementType == O.E {
    
    typealias E = ElementType
    typealias Parent = Catch<ElementType>
    
    fileprivate let _parent: Parent
    fileprivate let _subscription = SerialDisposable()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            forwardOn(.next(value))
        case .error(let e):
            do {
                let catchSequence = try _parent._handler(e)
                let observer = CatchSinkProxy(parent: self)
                _subscription.disposable = catchSequence.subscribe(observer)
            } catch let e {
                forwardOn(.error(e))
                dispose()
            }
        case .completed:
            forwardOn(.completed)
            dispose()
        }
    }
    
    func run() -> Disposable {
        let dispose = SingleAssignmentDisposable()
        _subscription.disposable = dispose
        dispose.setDisposable(_parent._source.subscribe(self))
        return _subscription
    }
}

fileprivate final class CatchSinkProxy<O: ObserverType>: ObserverType {
    
    typealias Parent = CatchSink<O.E, O>
    
    fileprivate let _parent: Parent
    
    init(parent: Parent) {
        _parent = parent
    }
    
    func on(_ event: Event<O.E>) {
        _parent.forwardOn(event)
        switch event {
        case .next: break
        case .error, .completed:
            _parent.dispose()
        }
    }
    
}

fileprivate final class CatchSequence<S: Sequence>: Producer<S.Iterator.Element.E> where S.Iterator.Element: ObservableConvertibleType {
    
    typealias ElementType = S.Iterator.Element.E
    
    fileprivate let _source: S
    
    init(source: S) {
        _source = source
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = CatchSequenceSink<S, O>(observer: observer, cancel: cancel)
        let subscription = sink.run((self._source.makeIterator(), nil))
        return (sink: sink, subscription: subscription)
    }
}

fileprivate final class CatchSequenceSink<S: Sequence, O: ObserverType>: TailRecursiveSink<S, O>, ObserverType where S.Iterator.Element: ObservableConvertibleType, S.Iterator.Element.E == O.E {
    
    typealias E = O.E
    typealias Parent = CatchSequence<S>
    
    private var _lastError: Error?
    
    func on(_ event: Event<O.E>) {
        switch event {
        case .next:
            forwardOn(event)
        case .error(let e):
            _lastError = e
            schedule(.moveNext)
        case .completed:
            forwardOn(event)
            dispose()
        }
    }
    
    override func extract(_ observable: Observable<O.E>) -> (generator: S.Iterator, remaining: IntMax?)? {
        if let onError = observable as? CatchSequence<S> {
            return (onError._source.makeIterator(), nil)
        } else {
            return nil
        }
    }
    
    override func subscribeToNext(_ source: Observable<O.E>) -> Disposable {
        return source.subscribe(self)
    }
    
    override func done() {
        if let lastError = _lastError {
            forwardOn(.error(lastError))
        } else {
            forwardOn(.completed)
        }
        dispose()
    }
    
}
