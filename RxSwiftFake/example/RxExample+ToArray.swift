//
//  RxExample+ToArray.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     toArray:
     收集所有事件，并且组装成一个数组。当原数据源发送Complete事件时，将这个数组发送出去。
     */
    static func testToArray() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.toArray().subscribe(onNext: { (s) in
            print("\(s)")
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
