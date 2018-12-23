//
//  SubscriptionDisposable.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/21.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

struct SubscriptionDisposable<T: SynchronizedUnsubscribeType>: Disposable {
    
    private let _key: T.DisposeKey
    
    private weak var _owner: T?
    
    init(owner: T, key: T.DisposeKey) {
        _owner = owner
        _key = key
    }
    
    func dispose() {
        _owner?.synchronizedUnsubscribe(_key)
    }
    
}
