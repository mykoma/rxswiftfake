//
//  RxExample+Delay.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     delay:
     将一个事件延迟N秒往后传递。
     */
    static func testDelay() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.delay(3, scheduler: MainScheduler.instance).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        print("send 1 2 3")
        p1.onNext(1)
        p1.onNext(2)
        p1.onNext(3)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            print("send 4 5")
            p1.onNext(4)
            p1.onNext(5)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                print("send 6 7")
                p1.onNext(6)
                p1.onNext(7)
                p1.onCompleted()
            }
        }
    }
    
}
