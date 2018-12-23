//
//  SynchronizedUnsubscribeType.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/21.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

protocol SynchronizedUnsubscribeType: class {
    
    associatedtype DisposeKey
    
    func synchronizedUnsubscribe(_ disposeKey: DisposeKey)
    
}
