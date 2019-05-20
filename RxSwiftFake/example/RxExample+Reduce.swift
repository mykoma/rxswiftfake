//
//  RxExample+Reduce.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     reduce:
     收集数据源中的所有的元素，通过指定规则计算，得出一个结果，当收到Completed事件，将结果发送出来。
     */
    static func testReduce() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.reduce(100, accumulator: { (a, b) -> Int in
            return a + b
        }).subscribe(onNext: { (s) in
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
        p1.onCompleted()
    }
    
}
