//
//  RxExample+Buffer.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/14.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     buffer:
     每缓存count个元素则组合起来一起发出。
     如果timeSpan秒钟内不够count个也会发出（有几个发几个，一个都没有发空数组 []）
     */
    static func testBuffer() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.buffer(timeSpan: 1, count: 3, scheduler: MainScheduler.instance).subscribe(onNext: { (s) in
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
        let time = DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            p1.onNext(3)
            p1.onNext(4)
            p1.onNext(5)
            p1.onNext(6)
            p1.onNext(7)
            p1.onCompleted()
        }
    }
    
}
