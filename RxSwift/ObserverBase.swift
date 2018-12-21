//
//  ObserverBase.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

 // Observer可以在中途stop
class ObserverBase<ElementType>: Disposable, ObserverType {
    
    typealias E = ElementType
    
    // 标记observer是否已经停止
    private var _isStopped = AtomicInt(0)
    
    func on(_ event: Event<E>) {
        switch event {
        case .next:
            if _isStopped.load() == 0  {
                onCore(event)
            }
        case .error, .completed:
            if _isStopped.fetchOr(1) == 0 {
                onCore(event)
            }
        }
    }
    
    func onCore(_ event:Event<E>) {
        rxAbstractMethod()
    }
    
    func dispose() {
        // 这里使用AtomicCompareAndSwap(OSAtomicCompareAndSwap32Barrier)的目的是因为>>原子操作<<
        // 下面的代码，主要逻辑就是先比较0和_isStopped，如果一致，将把1设置到_isStopped。
        // 一言概之：如果_isStopped是0，则设置_isStoppede为1
        
        /*
         _Bool OSAtomicCompareAndSwap32Barrier(int32_t __oldValue, int32_t __newValue, volatile int32_t *__theValue)
         This function compares the value in __oldValue to the value in the memory location referenced by __theValue.
         If the values match, this function stores the value from __newValue into that memory location atomically.
         */
//        Old code
//        _ = AtomicCompareAndSwap(0, 1, &_isStopped)
        
        _isStopped.fetchOr(1)
    }
    
}
