//
//  RxExample+Repeat.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/14.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     repeat:
     重复发送element，不会停止，不会发送error，completed。
     */
    static func testRepeat() {
        print("***************************************")
        _ = Observable<Int>.repeatElement(2).subscribe(onNext: { (s) in
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
