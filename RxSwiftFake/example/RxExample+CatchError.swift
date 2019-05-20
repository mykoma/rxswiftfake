//
//  RxExample+CatchError.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     catchError:
     原事件源正常发送事件并往后处理，如果发生error事件，则返回另外一个事件源来代替原事件源
     */
    static func testCatchError() {
        print("***************************************")
        let other = PublishSubject<Int>()
        let p1 = PublishSubject<Int>()
        _ = p1.catchError({ (e) -> Observable<Int> in
            return other
        }).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        other.onNext(11)
        p1.onNext(1)
        p1.onNext(2)
        other.onNext(12)
        p1.onError(NSError())
        p1.onNext(3)
        other.onNext(13)
        p1.onNext(4)
        p1.onNext(5)
        other.onNext(15)
        p1.onNext(6)
        p1.onNext(7)
        p1.onCompleted()
    }
    
}
