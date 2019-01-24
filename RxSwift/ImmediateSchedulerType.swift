//
//  ImmediateSchedulerType.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/24.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

protocol ImmediateSchedulerType {
    
    func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable
    
}

extension ImmediateSchedulerType {
    
    func scheduleRecursive<StateType>(_ state: StateType, action: @escaping (_ state: StateType, _ recurse: (StateType) -> ()) -> ()) -> Disposable {
        let recursiveScheduler = RecursiveImmediateScheduler(action: action, scheduler: self)
        recursiveScheduler.schedule(state)
        return Disposables.create(with: recursiveScheduler.dispose)
    }
    
}
