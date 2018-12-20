//
//  NopDisposable.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

fileprivate struct NopDisposable: Disposable {
    
    fileprivate static let noOp: Disposable = NopDisposable()
    
    fileprivate init() {
        
    }
    
    public func dispose() {
        // Do nothing
    }
    
}

extension Disposables {
    public static func create() -> Disposable {
        return NopDisposable.noOp
    }
}
