//
//  Cancelable.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

public protocol Cancelable: Disposable {
    
    var isDisposed: Bool { get }
    
}
