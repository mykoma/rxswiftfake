//
//  RxExample+Filter.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/27.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     filter:
     根据条件过来事件
     */
    static func testFilter() {
        print("***************************************")
        let sampler = PublishSubject<Int>()
        let p1 = PublishSubject<Int>()
        _ = p1.filter({ (a) -> Bool in
            return a > 3
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
