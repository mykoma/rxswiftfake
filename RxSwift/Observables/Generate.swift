//
//  Generate.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/2.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    static func generate(initialState: E,
                         condition: @escaping (E) throws -> Bool,
                         scheduler: ImmediateSchedulerType = CurrentThreadScheduler.instance,
                         iterate: @escaping (E) throws -> E) -> Observable<E> {
        return Generate(initialState: initialState, condition: condition, scheduler: scheduler, iterate: iterate)
    }
    
}

fileprivate final class Generate<E>: Producer<E> {
    
    fileprivate let _initialState: E
    fileprivate let _condition: (E) throws -> Bool
    fileprivate let _scheduler: ImmediateSchedulerType
    fileprivate let _iterate: (E) throws -> E
    
    init(initialState: E, condition: @escaping (E) throws -> Bool, scheduler: ImmediateSchedulerType, iterate: @escaping (E) throws -> E) {
        _initialState = initialState
        _condition = condition
        _scheduler = scheduler
        _iterate = iterate
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == E {
        let sink = GenerateSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate final class GenerateSink<O: ObserverType>: Sink<O> {
    
    typealias E = O.E
    typealias Parent = Generate<E>
    
    fileprivate let _parent: Parent
    fileprivate var _state: E
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        _state = _parent._initialState
        super.init(observer: observer, cancel: cancel)
    }
    
    func run() -> Disposable {
        return _parent._scheduler.scheduleRecursive(true, action: { (isFirst, recurse) in
            do {
                if !isFirst {
                    self._state = try self._parent._iterate(self._state)
                }
                if try self._parent._condition(self._state) {
                    self.forwardOn(.next(self._state))
                    recurse(false)
                } else {
                    self.forwardOn(.completed)
                    self.dispose()
                }
            } catch let e {
                self.forwardOn(.error(e))
                self.dispose()
            }
        })
    }
    
}
