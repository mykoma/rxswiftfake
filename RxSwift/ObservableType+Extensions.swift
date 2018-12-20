//
//  ObservableType+Extensions.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/20.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func subscribe(onNext: ((E) -> Void)? = nil,
                   onError: ((Swift.Error) -> Void)? = nil,
                   onCompleted: (() -> Void)? = nil,
                   onDisposed: (() -> Void)? = nil) -> Disposable {
        let disposable: Disposable
        if let disposed = onDisposed {
            disposable = Disposables.create(with: disposed)
        } else {
            disposable = Disposables.create()
        }
        
        /*
         1. 在下面的.error和.completed中，调用了disposable.dispose()，
            这里就是印证一个Observable只要发送了error或completed事件，也会释放资源
         2. Disposables.create( self.asObservable().subscribe(observer), disposable)
            在最后的返回值中，Disposables.create创建了BinaryDisposable，
            BinaryDisposable相当于就是合并了两个Disposable为一个新的Disposable，最后会同时调用这两个Disposable的dispose。
            即disposable也会通过DisposeBag的回收方式，调用dispose()
         综上，在1和2点，我们可以知道资源回收有两种方式：error和completed事件会触发资源回收，以及利用DisposeBag去回收资源
         */
        let observer = AnonymousObserver<E>.init { (event) in
            switch event {
            case .next(let value):
                onNext?(value)
            case .error(let error):
                if let onError = onError {
                    onError(error)
                }
                disposable.dispose()
            case .completed:
                onCompleted?()
                disposable.dispose()
            }
        }
        
        return Disposables.create(
            self.asObservable().subscribe(observer),
            disposable
        )
    }
    
}
