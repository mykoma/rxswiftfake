//
//  TailRecursiveSink.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/1.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

enum TailRecursiveSinkCommand {
    case moveNext
    case dispose
}

class TailRecursiveSink<S: Sequence, O: ObserverType>: Sink<O>, InvocableWithValueType where S.Iterator.Element: ObservableConvertibleType, S.Iterator.Element.E == O.E {

    typealias Value = TailRecursiveSinkCommand
    typealias E = O.E
    typealias SequenceGenerator = (generator: S.Iterator, remaining: IntMax?)
    
    var _generator: [SequenceGenerator] = []
    var _isDisposed = false
    var _subscription = SerialDisposable()
    
    var _gate = AsyncLock<InvocableScheduledItem<TailRecursiveSink<S, O>>>()
    
    func run(_ sources: SequenceGenerator) -> Disposable {
        _generator.append(sources)
        schedule(.moveNext)
        return _subscription
    }
    
    func invoke(_ command: TailRecursiveSinkCommand) {
        switch command {
        case .dispose:
            disposeCommand()
        case .moveNext:
            moveNextCommand()
        }
    }
    
    func schedule(_ command: TailRecursiveSinkCommand) {
        _gate.invoke(InvocableScheduledItem(invocable: self, state: command))
    }
    
    private func moveNextCommand() {
        var next: Observable<E>? = nil
        repeat {
            guard let (g, left) = _generator.last else { break }
            if _isDisposed { return }
            _generator.removeLast()
            
            var e = g
            guard let nextCandidate = e.next()?.asObservable() else { continue }
            
            if let knownOriginalLeft = left {
                if knownOriginalLeft - 1 >= 1 {
                    _generator.append((e, knownOriginalLeft - 1))
                }
            } else {
                _generator.append((e, nil))
            }
            
            if let nextGenerator = extract(nextCandidate) {
                _generator.append(nextGenerator)
            } else {
                next = nextCandidate
            }
        } while next == nil
        
        guard let existingNext = next else {
            done()
            return
        }
        
        let disposable = SingleAssignmentDisposable()
        _subscription.disposable = disposable
        disposable.setDisposable(subscribeToNext(existingNext))
    }
    
    func done() {
        forwardOn(.completed)
        dispose()
    }
    
    func extract(_ observable: Observable<E>) -> SequenceGenerator? {
        rxAbstractMethod()
    }
    
    func subscribeToNext(_ source: Observable<E>) -> Disposable {
        rxAbstractMethod()
    }
    
    private func disposeCommand() {
        _isDisposed = true
        _generator.removeAll(keepingCapacity: false)
    }
    
    override func dispose() {
        super.dispose()
        _subscription.dispose()
        _gate.dispose()
        schedule(.dispose)
    }
    
}
