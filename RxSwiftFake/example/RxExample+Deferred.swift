//
//  RxExample+Defer.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     Deferred:
     延迟创建事件源，直到有observer订阅的时候才创建事件源
     */
    static func testDeferred() {
        print("***************************************")
        _ = Observable<Int>.deferred({ () -> Observable<Int> in
            let ob1 = Observable<Int>.create({ ov in
                ov.onNext(1)
                ov.onNext(2)
                ov.onCompleted()
                return Disposables.create()
            })
            return ob1
        }).subscribe(onNext: { (s) in
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
