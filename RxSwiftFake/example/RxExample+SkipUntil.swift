//
//  RxSwift+SkipUntil.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/15.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     skipUntil:
     一直跳过元素，直到另外一个observable发出元素。
     */
    static func testSkipUntil() {
        print("***************************************")
        let untilPub = PublishSubject<String>()

        let p1 = PublishSubject<Int>()
        _ = p1.skipUntil(untilPub).subscribe(onNext: { (s) in
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
        untilPub.onNext("hello world")
        p1.onNext(5)
        p1.onNext(6)
        p1.onNext(7)
        p1.onCompleted()
    }
    
}
