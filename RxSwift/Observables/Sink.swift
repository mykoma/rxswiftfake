//
//  Sink.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/27.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

class Sink<O: ObserverType>: Disposable {
    
    fileprivate let _observer: O
    fileprivate let _cancel: Cancelable
    
    var _disposed: Bool
    final var disposed: Bool {
        return _disposed
    }
    
    init(observer: O, cancel: Cancelable) {
        _observer = observer
        _cancel = cancel
        _disposed = false
    }
    
    final func forwardOn(_ event: Event<O.E>) {
        if _disposed {
            return
        }
        _observer.on(event)
    }
    
    func dispose() {
        _disposed = true
        _cancel.dispose()
    }
    
}
