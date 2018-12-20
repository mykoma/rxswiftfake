//
//  Event.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

public enum Event<ElementType> {
    
    case next(ElementType)
    
    case error(Swift.Error)
    
    case completed
    
}
