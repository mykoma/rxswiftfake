//
//  RxExample+Window.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/29.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     window:
     将 Observable 分解为多个子 Observable，周期性的将子 Observable 发出来
     */
    static func testWindow() {
        print("***************************************")
        let p1 = PublishSubject<Int>()
        _ = p1.window(timeSpan: 3, count: 3, scheduler: MainScheduler.instance).subscribe(onNext: { (s) in
            print("\(s)")
            _ = s.asObservable().subscribe(onNext: { (a) in
                print("\(a) 22222")

            }, onError: { (e) in
                print("error: \(e) 22222")
            }, onCompleted: {
                print("onCompleted 22222")
            }, onDisposed: {
                print("disposed 22222")
            })
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
        print("time: \(Date()), send 1, 2")
        p1.onNext(1)
        p1.onNext(2)
        p1.onNext(20)
        p1.onNext(21)
        p1.onNext(22)
        p1.onNext(23)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            print("time: \(Date()), send 3 4 5")
            p1.onNext(3)
            p1.onNext(4)
            p1.onNext(5)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                print("time: \(Date()), send 6 7")
                p1.onNext(6)
                p1.onNext(7)
                p1.onCompleted()
            }
        }
    }
    
}
