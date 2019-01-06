//
//  Merge.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/1.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType where E: ObservableConvertibleType {
    
    func merge() -> Observable<E.E> {
        return Merge(source: self.asObservable())
    }
    
}

extension ObservableType {
    static func merge(_ sources: [Observable<E>]) -> Observable<E> {
        return MergeArray(sources: sources)
    }
}

final class MergeArray<ElementType>: Producer<ElementType> {
    
    private let _sources: [Observable<ElementType>]
    
    init(sources: [Observable<ElementType>]) {
        _sources = sources
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where E == O.E {
        let sink = MergeBasicSink<Observable<E>, O>(observer: observer, cancel: cancel)
        let subscription = sink.run(_sources)
        return (sink: sink, subscription: subscription)
    }
}

final class Merge<SourceSequence: ObservableConvertibleType>: Producer<SourceSequence.E> {
    
    private let _source: Observable<SourceSequence>
    
    init(source: Observable<SourceSequence>) {
        _source = source
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where SourceSequence.E == O.E {
        let sink = MergeBasicSink<SourceSequence, O>(observer: observer, cancel: cancel)
        let subscription = sink.run(_source)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class MergeBasicSink<S: ObservableConvertibleType, O: ObserverType>: MergeSink<S, S, O> where S.E == O.E {

    override func performMap(_ element: S) throws -> S {
        return element
    }
    
}

fileprivate class MergeSink<SourceElement, SourceSequence: ObservableConvertibleType, O: ObserverType>: Sink<O>, ObserverType where O.E == SourceSequence.E {
    typealias Element = SourceElement

    let _lock = RecursiveLock()
    let _sourceSubscription = SingleAssignmentDisposable()
    let _group = CompositeDisposable()
    var _activeCount = 0
    var _stopped = false
    
    func performMap(_ element: SourceElement) throws -> SourceSequence {
        rxAbstractMethod()
    }
    
    @inline(__always)
    final private func nextElementArrived(element: SourceElement) -> SourceSequence? {
        _lock.lock(); defer { _lock.unlock() }
        do {
            let value = try performMap(element)
            _activeCount += 1
            return value
        } catch let e {
            forwardOn(.error(e))
            dispose()
            return nil
        }
    }
    
    func on(_ event: Event<SourceElement>) {
        switch event {
        case .next(let element):
            if let value = nextElementArrived(element: element) {
                subscribeInner(value.asObservable())
            }
        case .error(let error):
            _lock.lock(); defer { _lock.unlock() }
            forwardOn(.error(error))
            dispose()
        case .completed:
            _lock.lock(); defer { _lock.unlock() }
            _stopped = true
            checkCompleted()
        }
    }
    
    func subscribeInner(_ source: Observable<O.E>) {
        let iterDisposable = SingleAssignmentDisposable()
        if let disposeKey = _group.insert(iterDisposable) {
            let iter = MergeSinkIter(parent: self, disposeKey: disposeKey)
            let subscription = source.asObservable().subscribe(iter)
            iterDisposable.setDisposable(subscription)
        }
    }
    
    @inline(__always)
    func checkCompleted() {
        if _stopped && _activeCount == 0 {
            forwardOn(.completed)
            dispose()
        }
    }
    
    func run(_ source: Observable<SourceElement>) -> Disposable {
        let _ = _group.insert(_sourceSubscription)
        let subscription = source.subscribe(self)
        _sourceSubscription.setDisposable(subscription)
        return _group
    }
    
    func run(_ sources: [Observable<O.E>]) -> Disposable {
        _activeCount += sources.count
        for source in sources {
            subscribeInner(source)
        }
        _stopped = true
        checkCompleted()
        return _group
    }
    
}

fileprivate final class MergeSinkIter
<SourceElement, SourceSequence: ObservableConvertibleType, O: ObserverType>: ObserverType where O.E == SourceSequence.E {
    
    typealias Parent = MergeSink<SourceElement, SourceSequence, O>
    typealias DisposeKey = CompositeDisposable.DisposeKey
    
    private let _parent: Parent
    private let _disposeKey: DisposeKey
    
    init(parent: Parent, disposeKey: DisposeKey) {
        _parent = parent
        _disposeKey = disposeKey
    }
    
    func on(_ event: Event<O.E>) {
        _parent._lock.lock(); defer { _parent._lock.unlock() }
        
        switch event {
        case .next(let element):
            _parent.forwardOn(.next(element))
        case .error(let error):
            _parent.forwardOn(.error(error))
            _parent.dispose()
        case .completed:
            _parent._group.remove(for: _disposeKey)
            _parent._activeCount -= 1
            _parent.checkCompleted()
        }
    }

}
