//
//  Observable.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

public class Observable<ElementType>: ObservableType {
    
    public typealias E = ElementType
    
    public func asObservable() -> Observable<ElementType> {
        return self
    }
    
    public func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        rxAbstractMethod()
    }
    
}
