//
//  RxExample+ElementAt.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/27.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     elementAt:
     获取第N个事件
     */
    static func testElementAt() {
        print("***************************************")
        let sampler = PublishSubject<Int>()
        let p1 = PublishSubject<Int>()
        _ = p1.elementAt(2).subscribe(onNext: { (s) in
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
