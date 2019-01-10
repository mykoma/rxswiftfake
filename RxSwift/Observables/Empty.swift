//
//  Empty.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/10.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    static func empty() -> Observable<E> {
        return EmptyProducer<E>()
    }
    
}

fileprivate final class EmptyProducer<ElementType>: Producer<ElementType> {
    
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        observer.onCompleted()
        return Disposables.create()
    }
    
}
