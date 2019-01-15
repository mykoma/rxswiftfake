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

extension Event {
    /// Is `completed` or `error` event.
    public var isStopEvent: Bool {
        switch self {
        case .next: return false
        case .error, .completed: return true
        }
    }
}
