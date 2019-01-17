//
//  GroupedObservable.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/17.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

struct GroupedObservable<KeyType, ElementType>: ObservableType {
    
    typealias E = ElementType
    public let _key: KeyType
    
    private let _source: Observable<ElementType>
    
    init(key: KeyType, source: Observable<ElementType>) {
        _key = key
        _source = source
    }
    
    func subscribe<O: ObserverType>(_ observer: O) -> Disposable where E == O.E {
        return _source.subscribe(observer)
    }
    
    func asObservable() -> Observable<ElementType> {
        return _source
    }
    
}
