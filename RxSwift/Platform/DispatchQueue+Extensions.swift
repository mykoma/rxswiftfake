//
//  DispatchQueue+Extensions.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/27.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension DispatchQueue {
    
    private static var token: DispatchSpecificKey<()> = {
        let key = DispatchSpecificKey<()>()
        DispatchQueue.main.setSpecific(key: key, value: ())
        return key
    }()
    
    static var isMain: Bool {
        return DispatchQueue.getSpecific(key: token) != nil
    }
    
}
