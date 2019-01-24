//
//  RxMutableBox.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/24.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

final class RxMutableBox<T>: CustomDebugStringConvertible {
    
    var value: T
    
    init(_ value: T) {
        self.value = value
    }
    
}

extension RxMutableBox {
    
    var debugDescription: String {
        return "MutatingBox(\(self.value))"
    }
}
