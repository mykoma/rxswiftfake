//
//  RxExample+Do.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     map:
     提供一个的分路，不影响正常的流程逻辑
     */
    static func testDo() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.do(onNext: { (a) in
            print("do \(a)")
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
