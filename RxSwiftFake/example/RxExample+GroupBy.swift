//
//  RxExample+GroupBy.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     groupBy:
     把事件按照某种规则分类，将同一类组装成一个新的Observable
     */
    static func testGroupBy() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.groupBy(keySelector: { (a) -> String in
            return a % 2 == 0 ? "Ou" : "Ji"
        }).subscribe(onNext: { (group) in
            _ = group.subscribe(onNext: { (x) in
                print("group: \(group._key), \(x)")
            })
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
