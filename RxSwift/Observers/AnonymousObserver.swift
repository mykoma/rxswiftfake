//
//  AnonymousObserver.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

final class AnonymousObserver<ElementType>: ObserverBase<ElementType> {
        
    typealias EventHandler = (Event<ElementType>) -> Void
    
    private let _eventHandler: EventHandler
    
    init(_ eventHandler: @escaping EventHandler) {
        _eventHandler = eventHandler
    }
    
    override func onCore(_ event: Event<ElementType>) {
        return _eventHandler(event)
    }
    
}
