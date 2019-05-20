//
//  RxExample+WithLatestFrom.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/29.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     withLatestFrom:
     将两个可观察序列合并为一个可观察序列，每当原事件源发送事件的时候，采用第二个事件源最新的事件去代替传递。(如果第二个事件源没有最新的事件，那么就没有任何事件往后传递)
     */
    static func testWithLatestFrom() {
        print("***************************************")
        let otherPub = PublishSubject<Int>()
        let p1 = PublishSubject<Int>()
        _ = p1.withLatestFrom(otherPub).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p1.onNext(1)
        otherPub.onNext(101)
        p1.onNext(2)
        p1.onNext(3)
        p1.onNext(4)
        otherPub.onNext(102)
        p1.onNext(5)
        p1.onNext(6)
        p1.onNext(7)
        p1.onCompleted()
    }
    
}
