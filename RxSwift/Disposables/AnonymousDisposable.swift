//
//  AnonymousDisposable.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

fileprivate final class AnonymousDisposable: DisposeBase, Cancelable {
    
    public typealias DisposeActiion = () -> Void
    
    private var _isDisposed: AtomicInt = 0
    private var _disposeAction: DisposeActiion
    
    fileprivate init(_ disposeAction: @escaping DisposeActiion) {
        _disposeAction = disposeAction
        super.init()
    }
    
    var isDisposed: Bool {
        return _isDisposed == 1
    }
    
    func dispose() {
        
    }
    
}

extension Disposables {
    public static func create(with dispose: @escaping () -> ()) -> Cancelable {
        return AnonymousDisposable(dispose)
    }
}
