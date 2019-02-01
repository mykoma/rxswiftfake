//
//  AsyncLock.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/1.
//  Copyright © 2019 goluk. All rights reserved.
//

final class AsyncLock<I: InvocableType>: Disposable, Lock, SynchronizedDisposeType {

    typealias Action = () -> Void
    
    var _lock = SpinLock()
    
    private var _queue: Queue<I> = Queue(capacity: 0)
    private var _isExecuting: Bool = false
    private var _hasFaulted: Bool = false
    
    func lock() {
        _lock.lock()
    }
    
    func unlock() {
        _lock.unlock()
    }
    
    private func enqueue(_ action: I) -> I? {
        _lock.lock(); defer { _lock.unlock() }
        if _hasFaulted { return nil }
        if _isExecuting {
            _queue.enqueue(action)
            return nil
        }
        _isExecuting = true
        return action
    }
    
    private func dequeue() -> I? {
        _lock.lock(); defer { _lock.unlock() }
        if !_queue.isEmpty {
            return _queue.dequeue()
        } else {
            _isExecuting = false
            return nil
        }
    }
    
    func invoke(_ action: I) {
        let firstEnqueueAction = enqueue(action)
        if let firstEnqueueAction = firstEnqueueAction {
            firstEnqueueAction.invoke()
        } else {
            return
        }
        while true {
            if let nextAction = dequeue() {
                nextAction.invoke()
            } else {
                return
            }
        }
    }
    
    func dispose() {
        synchronizedDispose()
    }
    
    func _synchronized_dispose() {
        _queue = Queue(capacity: 0)
        _hasFaulted = true
    }
    
}
