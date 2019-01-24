//
//  Producer.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/27.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

class Producer<ElementType>: Observable<ElementType> {
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        if !CurrentThreadScheduler.isScheduleRequired {
            let disposer = SinkDisposer()
            let sinkAndSubscription = run(observer, cancel: disposer)
            disposer.setSinkAndSubscription(sink: sinkAndSubscription.sink, subscription: sinkAndSubscription.subscription)
            return disposer
        } else {
            return CurrentThreadScheduler.instance.schedule(()) { _ -> Disposable in
                let disposer = SinkDisposer()
                let sinkAndSubscription = self.run(observer, cancel: disposer)
                disposer.setSinkAndSubscription(sink: sinkAndSubscription.sink, subscription: sinkAndSubscription.subscription)
                return disposer
            }
        }
    }
    
    func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        rxAbstractMethod()
    }
    
}

final class SinkDisposer: Cancelable {
    fileprivate enum DisposeState: Int32 {
        case disposed = 1
        case sinkAndSubscriptionSet = 2
    }
    
    var isDisposed: Bool {
        return _state.isFlagSet(DisposeState.disposed.rawValue)
    }
    
    private var _state = AtomicInt(0)
    private var _sink: Disposable? = nil
    private var _subscription: Disposable? = nil

    func setSinkAndSubscription(sink: Disposable, subscription: Disposable) {
        _sink = sink
        _subscription = subscription
        let previousState = _state.fetchOr(DisposeState.sinkAndSubscriptionSet.rawValue)
        if (previousState & DisposeState.sinkAndSubscriptionSet.rawValue) != 0 {
            rxFatalError("Sink and subscription were already set")
        }
        if (previousState & DisposeState.disposed.rawValue) != 0 {
            sink.dispose()
            subscription.dispose()
            _sink = nil
            _subscription = nil
        }
    }
    
    func dispose() {
        let previousState = _state.fetchOr(DisposeState.disposed.rawValue)
        if (previousState & DisposeState.disposed.rawValue) != 0 {
            return
        }
        if (previousState & DisposeState.sinkAndSubscriptionSet.rawValue) != 0 {
            guard let sink = _sink else {
                rxFatalError("sink not set")
            }
            guard let subscription = _subscription else {
                rxFatalError("subscription not set")
            }
            sink.dispose()
            subscription.dispose()
            _sink = nil
            _subscription = nil
        }
    }
    
}
