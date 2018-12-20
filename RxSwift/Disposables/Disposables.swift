//
//  Disposables.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

/// A collection of utility methods for common disposable operations.
/// Disposable的工具方法集合，方便调用如Disposables.create()等等，
/// 如果把create之类的方法放在Disposable里面，那么Disposable就需要去
/// 知道Disposable的具体实现，这样就破坏了--"依赖倒置原则"
public struct Disposables {
    private init() {}
}
