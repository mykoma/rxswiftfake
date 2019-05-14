//
//  RxExample+Amb.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/14.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     amb:
     给两个或多个Observable，amb只发送其中一个，不管是next,error,completed事件。
     哪个先执行完成，就发送哪一个，其他的全部忽略
     */
    static func testAmb1() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        let p2 = PublishSubject<Int>()
        _ = p1.amb(p2).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p2.onNext(1)
        p1.onNext(2)
        p1.onNext(3)
        p2.onNext(4)
        p1.onCompleted()
        p2.onCompleted()
    }
    
    static func testAmb2() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        let p2 = PublishSubject<Int>()
        _ = Observable<Int>.amb(p1, p2).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p2.onNext(10)
        p1.onNext(20)
        p1.onNext(30)
        p2.onNext(40)
        p1.onCompleted()
        p2.onCompleted()
    }
    
    static func testAmb3() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        let p2 = PublishSubject<Int>()
        _ = Observable<Int>.amb([p1, p2]).subscribe(onNext: { (s) in
            print("\(s)")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        p1.onNext(21)
        p2.onNext(11)
        p1.onNext(31)
        p2.onNext(41)
        p1.onCompleted()
        p2.onCompleted()
    }
}
