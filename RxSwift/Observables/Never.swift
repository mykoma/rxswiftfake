//
//  Never.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/15.
//  Copyright © 2019 goluk. All rights reserved.
//

extension ObservableType {
    
    static func never() -> Observable<E> {
        return NeverProducer()
    }
    
}

fileprivate final class NeverProducer<ElementType>: Producer<ElementType> {
    override func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        return Disposables.create()
    }
}
