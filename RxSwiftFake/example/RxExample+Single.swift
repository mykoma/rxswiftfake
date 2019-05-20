//
//  RxExample+Single.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/27.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     single:
     期望事件源只有一个Next事件，如果根据多余两个，则发送Error事件
     */
    static func testSingle() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.single({ (a) -> Bool in
            return a > 3
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
        p1.onNext(4)
        p1.onNext(5)
        p1.onNext(6)
        p1.onNext(7)
        p1.onCompleted()
    }
    
}
