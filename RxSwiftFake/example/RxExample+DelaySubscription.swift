//
//  RxExample+DelaySubscription.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     delaySubscription:
     延迟N秒订阅
     */
    static func testDelaySubscription() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.delaySubscription(3, scheduler: MainScheduler.instance)
            .subscribe(onNext: { (s) in
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
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            p1.onNext(4)
            p1.onNext(5)
            p1.onNext(6)
            p1.onNext(7)
            p1.onCompleted()
        }
    }
    
}
