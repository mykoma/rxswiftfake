//
//  MainScheduler.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/24.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

final class MainScheduler: SerialDispatchQueueScheduler {
    
    private let _mainQueue: DispatchQueue
    var numberEnqueued = AtomicInt(0)
    
    static let instance = MainScheduler()
    
    static let asyncInstance = SerialDispatchQueueScheduler(serialQueue: DispatchQueue.main)
    
    init() {
        _mainQueue = DispatchQueue.main
        super.init(serialQueue: _mainQueue)
    }
    
    class func ensureExecutingOnScheduler(errorMessage: String? = nil) {
        if !DispatchQueue.isMain {
            rxFatalError(errorMessage ?? "Executing on background thread. Please use `MainScheduler.instance.schedule` to schedule work on main thread.")
        }
    }
    
    override func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        let previousNumberEnqueued = numberEnqueued.increment()
        
        if DispatchQueue.isMain && previousNumberEnqueued == 0 {
            let dispose = action(state)
            numberEnqueued.decrement()
            return dispose
        }
        
        let cancel = SingleAssignmentDisposable()
        
        _mainQueue.async {
            if !cancel.isDisposed {
                _ = action(state)
            }
            self.numberEnqueued.decrement()
        }
        
        return cancel
    }
    
}
