//
//  SerialDispatchQueueScheduler.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/26.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

class SerialDispatchQueueScheduler: SchedulerType {
    var now: RxTime { return Date() }
    
    fileprivate let _configuration: DispatchQueueConfiguration
    
    init(serialQueue: DispatchQueue, leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0)) {
        _configuration = DispatchQueueConfiguration(queue: serialQueue, leeway: leeway)
    }
    
    public convenience init(internalSerialQueueName: String, serialQueueConfiguration: ((DispatchQueue) -> Void)? = nil, leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0)) {
        let queue = DispatchQueue(label: internalSerialQueueName, attributes: [])
        serialQueueConfiguration?(queue)
        self.init(serialQueue: queue, leeway: leeway)
    }
    
    public convenience init(queue: DispatchQueue, internalSerialQueueName: String, leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0)) {
        // Swift 3.0 IUO
        let serialQueue = DispatchQueue(label: internalSerialQueueName,
                                        attributes: [],
                                        target: queue)
        self.init(serialQueue: serialQueue, leeway: leeway)
    }
    
    @available(iOS 8, OSX 10.10, *)
    public convenience init(qos: DispatchQoS, internalSerialQueueName: String = "rx.global_dispatch_queue.serial", leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0)) {
        self.init(queue: DispatchQueue.global(qos: qos.qosClass), internalSerialQueueName: internalSerialQueueName, leeway: leeway)
    }
    
    func scheduleRelative<StateType>(_ state: StateType, dueTime: RxTimeInterval, action: @escaping (StateType) -> Disposable) -> Disposable {
        return _configuration.scheduleRelative(state, dueTime: dueTime, action: action)
    }
    
    func schedulePeriodic<StateType>(_ state: StateType, startAfter: RxTimeInterval, period: RxTimeInterval, action: @escaping (StateType) -> StateType) -> Disposable {
        return _configuration.schedulePeriodic(state, startAfter: startAfter, period: period, action: action)
    }
    
    func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        return _configuration.schedule(state, action: action)
    }
    
    
}
