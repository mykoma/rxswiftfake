//
//  InvocableType.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/24.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

protocol InvocableType {
    
    func invoke()
    
}

protocol InvocableWithValueType {
    
    associatedtype Value
    
    func invoke(_ value: Value)
    
}
