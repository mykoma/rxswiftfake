//
//  RxExample+Default.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     ifEmpty:
     如果事件源没有产生任何事件，那么在事件源发送Completed的时候，产生一个Next事件。
     */
    static func testIfEmpty() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.ifEmpty(default: 100).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p1.onCompleted()
    }
    
}
