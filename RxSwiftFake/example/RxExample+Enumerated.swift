//
//  RxExample+Enumerated.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     enumerated:
     将原始事件封装成一个包含index的事件
     */
    static func testEnumerated() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.enumerated().subscribe(onNext: { (index, element) in
            print("index: \(index), element: \(element)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p1.onNext(1)
        p1.onNext(2)
        p1.onNext(3)
        p1.onNext(4)
        p1.onNext(5)
        p1.onNext(6)
        p1.onNext(7)
        p1.onCompleted()
    }
    
}
