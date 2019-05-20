//
//  RxExample+SwitchIfEmpty.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     ifEmpty(switchTo:
     如果原事件源没有发送任何Next事件就Completed，那么就激活另外一个事件源来代替原事件源发送事件。
     */
    static func testSwitchIfEmpty() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        let p2 = PublishSubject<Int>()
        _ = p1.ifEmpty(switchTo: p2).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p1.onCompleted()
        p2.onNext(4)
        p2.onNext(5)
        p2.onNext(6)
        p2.onNext(7)
        p2.onCompleted()
    }
    
}
