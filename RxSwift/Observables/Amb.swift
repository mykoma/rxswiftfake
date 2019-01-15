//
//  Amb.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/15.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    static func amb<S: Sequence>(_ sequence: S) -> Observable<E> where S.Iterator.Element == Observable<E> {
        return sequence.reduce(Observable<S.Iterator.Element.E>.never()) { a, o in
            return a.amb(o.asObservable())
        }
    }
    
    static func amb<O: ObservableType>(_ observables: O...) -> Observable<E> where O.E == E {
        return observables.reduce(Observable<E>.never()) { a, o in
            return a.amb(o.asObservable())
        }
    }
    
}

extension ObservableType {
    
    func amb<O2: ObservableType>(_ right: O2) -> Observable<E> where O2.E == E {
        return Amb(left: asObservable(), right: right.asObservable())
    }
    
}

fileprivate enum AmbState {
    case neither
    case left
    case right
}

fileprivate final class Amb<ElementType>: Producer<ElementType> {
    fileprivate let _left: Observable<ElementType>
    fileprivate let _right: Observable<ElementType>
    
    init(left: Observable<ElementType>, right: Observable<ElementType>) {
        _left = left
        _right = right
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = AmbSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
}

fileprivate final class AmbSink<O: ObserverType>: Sink<O> {
    
    typealias ElementType = O.E
    typealias Parent = Amb<ElementType>
    typealias AmbObserverType = AmbObserver<O>
    
    fileprivate let _parent: Parent
    fileprivate let _lock = RecursiveLock()
    fileprivate var _choice = AmbState.neither
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }
    
    func run() -> Disposable {
        let subscription1 = SingleAssignmentDisposable()
        let subscription2 = SingleAssignmentDisposable()
        
        let disposeAll = Disposables.create(subscription1, subscription2)
        
        let forwardEvent = { (o: AmbObserver<O>, event: Event<ElementType>) in
            self.forwardOn(event)
            if event.isStopEvent {
                self.dispose()
            }
        }
        
        let decide = { (o: AmbObserverType, event: Event<ElementType>, me: AmbState, otherSubscription: Disposable) in
            self._lock.performLocked({
                if self._choice == .neither {
                    self._choice = me
                    o._sink = forwardEvent
                    o._cancel = disposeAll
                    otherSubscription.dispose()
                }
                
                if self._choice == me {
                    self.forwardOn(event)
                    if event.isStopEvent {
                        self.dispose()
                    }
                }
            })
        }
        
        let sink1 = AmbObserver(parent: self, cancel: subscription1) { (o, e) in
            decide(o, e, .left, subscription2)
        }
        
        let sink2 = AmbObserver(parent: self, cancel: subscription2) { (o, e) in
            decide(o, e, .right, subscription1)
        }
        
        subscription1.setDisposable(_parent._left.subscribe(sink1))
        subscription2.setDisposable(_parent._right.subscribe(sink2))

        return disposeAll
    }
}

fileprivate final class AmbObserver<O: ObserverType>: ObserverType {

    typealias Parent = AmbSink<O>
    typealias Sink = (AmbObserver<O>, Event<O.E>) -> Void
    
    fileprivate let _parent: Parent
    fileprivate var _cancel: Disposable
    fileprivate var _sink: Sink
    
    init(parent: Parent, cancel: Disposable, sink: @escaping Sink) {
        _parent = parent
        _cancel = cancel
        _sink = sink
    }
    
    func on(_ event: Event<O.E>) {
        _sink(self, event)
        if event.isStopEvent {
            _cancel.dispose()
        }
    }

}
