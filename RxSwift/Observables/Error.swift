//
//  Error.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/21.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    static func error(_ error: Swift.Error) -> Observable<E> {
        return ErrorProducer(error: error)
    }
    
}

fileprivate final class ErrorProducer<ElementType>: Producer<ElementType> {
    
    fileprivate let _error: Swift.Error
    
    init(error: Swift.Error) {
        _error = error
    }
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        observer.onError(_error)
        return Disposables.create()
    }
    
}
