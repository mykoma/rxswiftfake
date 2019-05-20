//
//  RxExample+Scan.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/14.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     scan:
     传递一个初始的seed，当收到一个元素，然后和这个元素进行一次变换，
     得到一个返回值，即当前元素的产生的输出值，然后这个返回值和剩下的其他元素，递归变换。
     */
    static func testScan() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        let seed: String = "ABC"
        _ = p1.scan(seed, accumulator: { (r, element) -> String in
            return "\(element)_\(r) + \(element * 2)"
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
