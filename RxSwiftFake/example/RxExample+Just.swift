//
//  RxExample+Just.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     Just:
     发送一次事件，就发送Completed结束。
     */
    static func testJust() {
        print("***************************************")
        _ = Observable<Int>.just(12).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
    }
    
}
