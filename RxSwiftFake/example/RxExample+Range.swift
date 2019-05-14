//
//  RxExample+Range.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/14.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     range:
     创建一个从start开始，增量为1，个数为count的数字observable
     */
    static func testRange() {
        print("***************************************")
        _ = Observable<Int>.range(start: 3, count: 3).subscribe(onNext: { (s) in
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
