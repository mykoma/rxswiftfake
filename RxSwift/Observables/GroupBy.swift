//
//  GroupBy.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/17.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func groupBy<K: Hashable>(keySelector: @escaping (E) throws -> K) -> Observable<GroupedObservable<K, E>> {
        return GroupBy(source: asObservable(), keySelector: keySelector)
    }
    
}

fileprivate final class GroupBy<KeyType: Hashable, ElementType>: Producer<GroupedObservable<KeyType, ElementType>> {
    
    typealias KeySelector = (ElementType) throws -> KeyType
    
    fileprivate let _keySelector: KeySelector
    fileprivate let _source: Observable<ElementType>
    
    init(source: Observable<ElementType>, keySelector: @escaping KeySelector) {
        _source = source
        _keySelector = keySelector
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == GroupedObservable<KeyType, ElementType> {
        let sink = GroupBySink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class GroupBySink<KeyType: Hashable, ElementType, O: ObserverType>: Sink<O>, ObserverType where O.E == GroupedObservable<KeyType, ElementType> {
    
    typealias Parent = GroupBy<KeyType, ElementType>
    
    fileprivate let _parent: Parent
    fileprivate let _subscription = SingleAssignmentDisposable()
    fileprivate var _refCountDisposable: RefCountDisposable!
    fileprivate var _groupedSubjectTable = [KeyType: PublishSubject<ElementType>]()

    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    private func onGroupEvent(key: KeyType, value: ElementType) {
        if let writer = _groupedSubjectTable[key] {
            writer.on(.next(value))
        } else {
            let writer = PublishSubject<ElementType>()
            _groupedSubjectTable[key] = writer
            let groupBySinkImpl = GroupBySinkImpl(subject: writer, refCount: _refCountDisposable)
            let group = GroupedObservable(key: key,
                                          source: groupBySinkImpl)
            forwardOn(.next(group))
            writer.on(.next(value))
        }
    }
    
    func on(_ event: Event<ElementType>) {
        switch event {
        case .next(let value):
            do {
                let key = try _parent._keySelector(value)
                onGroupEvent(key: key, value: value)
            } catch let e {
                error(e)
                return
            }
        case .completed:
            forwardOnGroups(event: .completed)
            forwardOn(.completed)
            _subscription.dispose()
            dispose()
            break
        case .error(let e):
            error(e)
            break
        }
    }
    
    func run() -> Disposable {
        _refCountDisposable = RefCountDisposable(disposable: _subscription)
        let disposable = _parent._source.subscribe(self)
        _subscription.setDisposable(disposable)
        return _refCountDisposable
    }
    
    final func error(_ error: Swift.Error) {
        forwardOnGroups(event: .error(error))
        forwardOn(.error(error))
        _subscription.dispose()
        dispose()
    }
    
    final func forwardOnGroups(event: Event<ElementType>) {
        for writer in _groupedSubjectTable.values {
            writer.on(event)
        }
    }
    
}

fileprivate final class GroupBySinkImpl<ElementType>: Observable<ElementType> {
    
    private let _subject: PublishSubject<ElementType>
    private var _refCount: RefCountDisposable

    init(subject: PublishSubject<ElementType>, refCount: RefCountDisposable) {
        _subject = subject
        _refCount = refCount
    }
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == ElementType {
        let release = _refCount.retain()
        let subscription = _subject.subscribe(observer)
        return Disposables.create(release, subscription)
    }
    
}
