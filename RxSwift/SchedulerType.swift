//
//  SchedulerType.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/24.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

typealias RxTimeInterval = TimeInterval
typealias RxTime = Date

protocol SchedulerType: ImmediateSchedulerType {
    
    var now: RxTime { get }
    
    func scheduleRelative<StateType>(_ state: StateType, dueTime: RxTimeInterval, action: @escaping (StateType) -> Disposable)  -> Disposable
    
    func schedulePeriodic<StateType>(_ state: StateType, startAfter: RxTimeInterval, period: RxTimeInterval, action: @escaping (StateType) -> StateType) -> Disposable

}

extension SchedulerType {
    
    func schedulePeriodic<StateType>(_ state: StateType, startAfter: RxTimeInterval, period: RxTimeInterval, action: @escaping (StateType) -> StateType) -> Disposable {
        let scheduler = SchedulePeriodicRecursive(scheduler: self, startAfter: startAfter, period: period, action: action, state: state)
        return scheduler.start()
    }
    
    func scheduleRecursive<StateType>(_ state: StateType, dueTime: RxTimeInterval, action: @escaping (StateType, AnyRecursiveScheduler<StateType>) -> ()) -> Disposable {
        let scheduler = AnyRecursiveScheduler(scheduler: self, action: action)
        scheduler.schedule(state, dueTime: dueTime)
        return Disposables.create(with: scheduler.dispose)
    }
    
}
