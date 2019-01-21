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
    
    private var _isDisposed = AtomicInt(0)
    private var _disposeAction: DisposeActiion?
    
    fileprivate init(_ disposeAction: @escaping DisposeActiion) {
        _disposeAction = disposeAction
        super.init()
    }
    
    var isDisposed: Bool {
        return _isDisposed.isFlagSet(1)
    }
    
    func dispose() {
        if _isDisposed.fetchOr(1) == 0 {
            assert(_isDisposed.load() == 1)
            if let action = _disposeAction {
                _disposeAction = nil
                action()
            }
        }
    }
    
}

extension Disposables {
    public static func create(with dispose: @escaping () -> ()) -> Cancelable {
        return AnonymousDisposable(dispose)
    }
}
