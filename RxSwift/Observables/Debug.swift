//
//  Debug.swift
//  RxSwiftFake
//
//  Created by Gang on 2019/1/23.
//  Copyright © 2019 goluk. All rights reserved.
//

import Foundation

extension ObservableType {
    
    func debug(_ identifier: String? = nil,
               trimOutput: Bool = false,
               file: String = #file,
               line: UInt = #line,
               function: String = #function) -> Observable<E> {
        return Debug(source: asObservable(),
                     identifier: identifier,
                     trimOutput: trimOutput,
                     file: file,
                     line: line,
                     function: function)
    }
    
}

fileprivate final class Debug<ElementType>: Producer<ElementType> {
    
    fileprivate let _source: Observable<ElementType>
    fileprivate let _identifier: String
    fileprivate let _trimOutput: Bool

    init(source: Observable<ElementType>, identifier: String?, trimOutput: Bool, file: String, line: UInt, function: String) {
        _trimOutput = trimOutput
        _source = source
        if let identifier = identifier {
            _identifier = identifier
        } else {
            let trimmedFile: String
            if let lastIndex = file.lastIndexOf("/") {
                trimmedFile = String(file[file.index(after: lastIndex) ..< file.endIndex])
            }
            else {
                trimmedFile = file
            }
            _identifier = "\(trimmedFile):\(line) (\(function))"
        }
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ElementType {
        let sink = DebugSink(parent: self, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
    
}

fileprivate let dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

fileprivate func logEvent(_ identifier: String, dateFormat: DateFormatter, content: String) {
    print("\(dateFormat.string(from: Date())): \(identifier) -> \(content)")
}

fileprivate final class DebugSink<ElementType, O: ObserverType>: Sink<O>, ObserverType where ElementType == O.E {
    
    typealias E = ElementType
    typealias Parent = Debug<ElementType>
    
    fileprivate let _parent: Parent
    fileprivate let _timestampFormatter = DateFormatter()
    
    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        _timestampFormatter.dateFormat = dateFormat
        logEvent(_parent._identifier, dateFormat: _timestampFormatter, content: "subscribed")
        super.init(observer: observer, cancel: cancel)
    }

    func on(_ event: Event<E>) {
        let maxEventTextLength = 40
        let eventText = "\(event)"
        
        let eventNormalized = (eventText.count > maxEventTextLength) && _parent._trimOutput
            ? String(eventText.prefix(maxEventTextLength / 2)) + "..." + String(eventText.suffix(maxEventTextLength / 2))
            : eventText
        
        logEvent(_parent._identifier, dateFormat: _timestampFormatter, content: "Event \(eventNormalized)")
        
        forwardOn(event)
        if event.isStopEvent {
            dispose()
        }
    }
    
    override func dispose() {
        if !self.isDisposed {
            logEvent(_parent._identifier, dateFormat: _timestampFormatter, content: "disposed")
        }
        super.dispose()
    }

}
