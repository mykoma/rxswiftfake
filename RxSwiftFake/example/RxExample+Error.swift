//
//  RxExample+Error.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/5/28.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension RxExample {
    
    /**
     error:
     产生一个error事件
     */
    static func testError() {
        print("***************************************")
        _ = Observable<Int>.error(NSError(domain: "test", code: 1, userInfo: nil) as Error).subscribe(onNext: { (_) in
            print("onNext")
        }, onError: { (e) in
            print("onError: \(e)")
        }, onCompleted: {
            print("onCompleted")
        }) {
            print("disposed")
        }
    }
    
}
