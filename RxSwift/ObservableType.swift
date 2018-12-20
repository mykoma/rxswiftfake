//
//  ObservableType.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

public protocol ObservableType: ObservableConvertibleType {
    
    func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E
    
}
