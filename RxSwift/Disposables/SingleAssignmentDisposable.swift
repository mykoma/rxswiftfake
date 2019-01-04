//
//  SingleAssignmentDisposable.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/4.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

final class SingleAssignmentDisposable: DisposeBase, Cancelable {
    
    fileprivate enum DisposeState: Int32 {
        case disposed = 1
        case disposableSet = 2
    }
    
    private var _state = AtomicInt(0)
    private var _disposable = nil as Disposable?
    
    var isDisposed: Bool {
        return _state.isFlagSet(DisposeState.disposed.rawValue)
    }
    
    public func setDisposable(_ disposable: Disposable) {
        _disposable = disposable
        
        let previousState = _state.fetchOr(DisposeState.disposableSet.rawValue)
        
        if (previousState & DisposeState.disposableSet.rawValue) != 0 {
            rxFatalError("oldState.disposable != nil")
        }
        
        if (previousState & DisposeState.disposed.rawValue) != 0 {
            disposable.dispose()
            _disposable = nil
        }
    }
    
    func dispose() {
        let previousState = _state.fetchOr(DisposeState.disposed.rawValue)
        if (previousState & DisposeState.disposed.rawValue) != 0 {
            return
        }
        
        if (previousState & DisposeState.disposableSet.rawValue) != 0 {
            guard let disposable = _disposable else {
                rxFatalError("Disposable not set")
            }
            disposable.dispose()
            _disposable = nil
        }
    }
    
}
