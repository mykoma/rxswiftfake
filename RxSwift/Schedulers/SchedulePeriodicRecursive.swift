//
//  SchedulePeriodicRecursive.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/24.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

enum SchedulePeriodicRecursiveCommand {
    case tick
    case dispatchStart
}

final class SchedulePeriodicRecursive<State> {
    
    typealias RecursiveAction = (State) -> State
    typealias RecursiveScheduler = AnyRecursiveScheduler<SchedulePeriodicRecursiveCommand>
    
    private let _scheduler: SchedulerType
    private let _startAfter: RxTimeInterval
    private let _period: RxTimeInterval
    private let _action: RecursiveAction
    
    private var _state: State
    private var _pendingTickCount = AtomicInt(0)
    
    init(scheduler: SchedulerType, startAfter: RxTimeInterval, period: RxTimeInterval, action: @escaping RecursiveAction, state: State) {
        _scheduler = scheduler
        _startAfter = startAfter
        _period = period
        _action = action
        _state = state
    }
    
    func start() -> Disposable {
        return _scheduler.scheduleRecursive(SchedulePeriodicRecursiveCommand.tick,
                                            dueTime: _startAfter,
                                            action: self.tick)
    }
    
    func tick(_ command: SchedulePeriodicRecursiveCommand, scheduler: RecursiveScheduler) {
        switch command {
        case .tick:
            scheduler.schedule(.tick, dueTime: _period)
            if _pendingTickCount.increment() == 0 {
                self.tick(.dispatchStart, scheduler: scheduler)
            }
        case .dispatchStart:
            _state = _action(_state)
            if _pendingTickCount.decrement() > 1 {
                scheduler.schedule(SchedulePeriodicRecursiveCommand.dispatchStart)
            }
        }
    }
    
}
