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
    
    /// If `next` event, returns element value.
    public var element: ElementType? {
        if case .next(let value) = self {
            return value
        }
        return nil
    }
    
    /// If `error` event, returns error.
    public var error: Swift.Error? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
    
    /// If `completed` event, returns `true`.
    public var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }
    
}
