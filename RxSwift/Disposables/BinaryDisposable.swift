//
//  BinaryDisposable.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

fileprivate final class BinaryDisposable: DisposeBase, Cancelable {
    
    private var _isDisposed = AtomicInt(0)
    
    private var _disposable1: Disposable?
    private var _disposable2: Disposable?
    
    var isDisposed: Bool {
        return _isDisposed.isFlagSet(1)
    }
    
    init(_ disposable1: Disposable, _ disposable2: Disposable) {
        _disposable1 = disposable1
        _disposable2 = disposable2
        super.init()
    }
    
    func dispose() {
        if _isDisposed.fetchOr(1) == 0 {
            _disposable1?.dispose()
            _disposable2?.dispose()
            _disposable1 = nil
            _disposable2 = nil
        }
    }
    
}

extension Disposables {
    
    public static func create(_ disposable1: Disposable, _ disposable2: Disposable) -> Cancelable {
        return BinaryDisposable(disposable1, disposable2)
    }
    
}
