//
//  SwiftSupport.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/1.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

typealias IntMax = Int64
public typealias RxAbstractInteger = FixedWidthInteger

extension SignedInteger {
    func toIntMax() -> IntMax {
        return IntMax(self)
    }
}
