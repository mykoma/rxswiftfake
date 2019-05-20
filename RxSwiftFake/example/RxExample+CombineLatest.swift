//
//  RxExample+CombineLatest.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     combineLatest:
     组合两个事件源，只要其中一个发送了事件，那么将这两个事件源最近发送的事件，交由一个指定的函数去处理生成新的事件。
     */
    static func testCombineLatest() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        let p2 = PublishSubject<Int>()
        _ = Observable.combineLatest(p1, p2, resultSelector: { (a, b) -> String in
            return "NEW: \(a), \(b)"
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
        p2.onNext(0)
        
        p1.onNext(3)
        p1.onNext(4)
        p2.onNext(1)
        p1.onNext(5)
        p2.onNext(1)
        p1.onNext(6)
        p1.onNext(7)
        p1.onCompleted()
    }
    
}
