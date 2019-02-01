//
//  InvocableScheduledItem.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/2/1.
//  Copyright © 2019 goluk. All rights reserved.
//

struct InvocableScheduledItem<I: InvocableWithValueType>: InvocableType {
    
    let _invocable: I
    let _state: I.Value
    
    init(invocable: I, state: I.Value) {
        _invocable = invocable
        _state = state
    }
    
    func invoke() {
        _invocable.invoke(_state)
    }
    
}
