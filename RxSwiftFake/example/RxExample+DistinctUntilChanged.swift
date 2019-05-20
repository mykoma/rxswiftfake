//
//  RxExample+DistinctUntilChanged.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     distinctUntilChanged:
     忽略相同的事件
     */
    static func testDistinctUntilChanged() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.distinctUntilChanged().subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p1.onNext(1)
        p1.onNext(1)
        p1.onNext(1)
        p1.onNext(2)
        p1.onNext(3)
        p1.onNext(3)
        p1.onNext(4)
        p1.onNext(5)
        p1.onNext(5)
        p1.onNext(6)
        p1.onNext(7)
        p1.onCompleted()
    }
    
}
