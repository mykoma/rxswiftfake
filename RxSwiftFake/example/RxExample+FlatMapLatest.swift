//
//  RxExample+FlatMapLast.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/15.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     flatMapLatest:
     原始observable能够变换要激活的其他observable，
     */
    static func testFlatMapLatest() {
        print("***************************************")
        let pub1 = PublishSubject<String>()
        let pub2 = PublishSubject<String>()
        let pub3 = PublishSubject<String>()

        let p1 = PublishSubject<Int>()
        _ = p1.flatMapLatest({ (a) -> Observable<String> in
            if a == 1 || a == 4 {
                return pub1
            } else if a == 2 || a == 5 {
                return pub2
            } else {
                return pub3
            }
        }).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p1.onNext(1)
        pub1.onNext("pub1 hello 1")
        pub2.onNext("pub2 hello 1")
        pub3.onNext("pub3 hello 1")
        p1.onNext(2)
        pub1.onNext("pub1 hello 2")
        pub2.onNext("pub2 hello 2")
        pub3.onNext("pub3 hello 2")
        p1.onNext(3)
        pub1.onNext("pub1 hello 3")
        pub2.onNext("pub2 hello 3")
        pub3.onNext("pub3 hello 3")
        p1.onNext(4)
        pub1.onNext("pub1 hello 4")
        pub2.onNext("pub2 hello 4")
        pub3.onNext("pub3 hello 4")
        p1.onNext(5)
        p1.onNext(6)
        p1.onNext(7)
        p1.onCompleted()
    }
    
}
