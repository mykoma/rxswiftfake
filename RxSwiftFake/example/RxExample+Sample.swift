//
//  RxExample+Sample.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/27.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     sample:
     事件源发送的事件，不会立即被接收到，直到sample发送事件，没收到一个sample事件，事件源发送的最近的一个事件就会被传递出去。
     */
    static func testSample() {
        print("***************************************")
        let sampler = PublishSubject<Int>()
        let p1 = PublishSubject<Int>()
        _ = p1.sample(sampler).subscribe(onNext: { (s) in
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
        sampler.onNext(0)
        
        p1.onNext(3)
        p1.onNext(4)
        sampler.onNext(1)
        p1.onNext(5)
        sampler.onNext(1)
        p1.onNext(6)
        p1.onNext(7)
        p1.onCompleted()
    }
    
}
