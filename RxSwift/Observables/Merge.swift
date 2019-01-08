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
    
    func merge(maxConcurrent: Int) -> Observable<E.E> {
        return MergeLimited(sources: self.asObservable(), maxConcurrent: maxConcurrent)
    }
    
}

extension ObservableType {
    
    static func merge(_ sources: [Observable<E>]) -> Observable<E> {
        return MergeArray(sources: sources)
    }
    
    static func merge(_ sources: Observable<E>...) -> Observable<E> {
        return MergeArray(sources: sources)
    }
    
}

// MARK: - MergeArray

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

// MARK: - Merge

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

// MARK: - MergeLimited

final class MergeLimited<SourceSequence: ObservableConvertibleType>: Producer<SourceSequence.E> {
    
    private let _sources: Observable<SourceSequence>
    private let _maxConcurrent: Int
    
    init(sources: Observable<SourceSequence>, maxConcurrent: Int) {
        _sources = sources
        _maxConcurrent = maxConcurrent
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where SourceSequence.E == O.E {
        let sink = MergeLimitedBasicSink<SourceSequence, O>(maxConcurrent: _maxConcurrent, observer: observer, cancel: cancel)
        let subscription = sink.run(_sources)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class MergeLimitedBasicSink<SourceSequence: ObservableConvertibleType, O: ObserverType>: MergeLimitedSink<SourceSequence, SourceSequence, O> where O.E == SourceSequence.E {
    
    override func performMap(_ element: SourceSequence) throws -> SourceSequence {
        return element
    }
    
}

fileprivate class MergeLimitedSink<SourceElement, SourceSequence: ObservableConvertibleType, O: ObserverType>: Sink<O>, ObserverType where O.E == SourceSequence.E {
    
    typealias QueueType = Queue<SourceSequence>
    
    let _maxConcurrent: Int
    var _stopped = false
    private let _sourceSubscription = SingleAssignmentDisposable()
    fileprivate var _activeCount = 0
    fileprivate var _queue = QueueType(capacity: 2)
    fileprivate let _group = CompositeDisposable()
    fileprivate let _lock = RecursiveLock()
    
    init(maxConcurrent: Int, observer: O, cancel: Cancelable) {
        _maxConcurrent = maxConcurrent
        super.init(observer: observer, cancel: cancel)
    }
    
    func run(_ source: Observable<SourceElement>) -> Disposable {
        let _ = _group.insert(_sourceSubscription)
        let disposable = source.subscribe(self)
        _sourceSubscription.setDisposable(disposable)
        return _group
    }
    
    func performMap(_ element: SourceElement) throws -> SourceSequence {
        rxAbstractMethod()
    }
    
    func subscribe(_ innerSource: SourceSequence, group: CompositeDisposable) {
        let subscription = SingleAssignmentDisposable()
        let key = _group.insert(subscription)
        
        if let key = key {
            let observer = MergeLimitedSinkIter(parent: self, disposeKey: key)
            let disposable = innerSource.asObservable().subscribe(observer)
            subscription.setDisposable(disposable)
        }
    }
    
    @inline(__always)
    final fileprivate func nextElementArrived(element: SourceElement) -> SourceSequence? {
        _lock.lock(); defer { _lock.unlock() }
        let subscribe: Bool
        if _activeCount < _maxConcurrent {
            _activeCount += 1
            subscribe = true
        } else {
            do {
                let value = try performMap(element)
                _queue.enqueue(value)
            } catch {
                forwardOn(.error(error))
                dispose()
            }
            subscribe = false
        }
        
        if subscribe {
            do {
                return try performMap(element)
            } catch {
                forwardOn(.error(error))
                dispose()
            }
        }
        
        return nil
    }
    
    func on(_ event: Event<SourceElement>) {
        switch event {
        case .next(let element):
            if let sequence = self.nextElementArrived(element: element) {
                self.subscribe(sequence, group: _group)
            }
        case .error(let error):
            _lock.lock(); defer { _lock.unlock() }
            forwardOn(.error(error))
            dispose()
        case .completed:
            _lock.lock(); defer { _lock.unlock() }
            if _activeCount == 0 {
                forwardOn(.completed)
                dispose()
            } else {
                _sourceSubscription.dispose()
            }
            _stopped = true
        }
    }

}

fileprivate final class MergeLimitedSinkIter<SourceElement, SourceSequence: ObservableConvertibleType, O: ObserverType>: ObserverType, LockOwnerType, SynchronizedOnType where SourceSequence.E == O.E {

    typealias Parent = MergeLimitedSink<SourceElement, SourceSequence, O>
    typealias DisposeKey = CompositeDisposable.DisposeKey
    typealias E = O.E
    
    private let _parent: Parent
    private let _disposeKey: DisposeKey
    
    init(parent: Parent, disposeKey: DisposeKey) {
        _parent = parent
        _disposeKey = disposeKey
    }
    
    var _lock: RecursiveLock {
        return _parent._lock
    }
    
    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }
    
    func _synchronized_on(_ event: Event<E>) {
        switch event {
        case .next(let element):
            _parent.forwardOn(.next(element))
        case .error(let error):
            _parent.forwardOn(.error(error))
            _parent.dispose()
        case .completed:
            _parent._group.remove(for: _disposeKey)
            if let next = _parent._queue.dequeue() {
                _parent.subscribe(next, group: _parent._group)
            } else {
                _parent._activeCount -= 1
                if _parent._stopped && _parent._activeCount == 0 {
                    _parent.forwardOn(.completed)
                    _parent.dispose()
                }
            }
        }
    }
    
}
