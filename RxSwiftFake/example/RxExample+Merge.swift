//
//  RxExample+Merge.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/27.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     merge:
     多个observable，把他们合并起来，形成一个新的observable
     */
    static func testMerge() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        let p2 = PublishSubject<Int>()
        let p3 = PublishSubject<Int>()
        _ = Observable.merge(p1, p2, p3).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p1.onNext(1)
        p2.onNext(2)
        p3.onNext(3)
        p1.onNext(4)
        p2.onNext(5)
        p3.onNext(6)
        p1.onNext(7)
    }
    
}
