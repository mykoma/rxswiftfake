//
//  SynchronizedDisposeType.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/1.
//  Copyright © 2019 goluk. All rights reserved.
//

protocol SynchronizedDisposeType: class, Disposable, Lock {
    
    func _synchronized_dispose()
    
}

extension SynchronizedDisposeType {
    
    func synchronizedDispose() {
        lock(); defer { unlock() }
        _synchronized_dispose()
    }
    
}
