//
//  ObserverType.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

public protocol ObserverType {
    
    associatedtype E
    
    func on(_ event: Event<E>)
    
}
