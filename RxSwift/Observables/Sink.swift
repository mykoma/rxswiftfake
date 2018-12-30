//
//  Sink.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/27.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

class Sink<O: ObserverType>: Cancelable {
    
    fileprivate let _observer: O
    fileprivate let _cancel: Cancelable
    
    var _isDisposed: Bool
    var isDisposed: Bool {
        return _isDisposed
    }
    
    init(observer: O, cancel: Cancelable) {
        _observer = observer
        _cancel = cancel
        _isDisposed = false
    }
    
    final func forwardOn(_ event: Event<O.E>) {
        if isDisposed {
            return
        }
        _observer.on(event)
    }
    
    func dispose() {
        _isDisposed = true
        _cancel.dispose()
    }
    
}
