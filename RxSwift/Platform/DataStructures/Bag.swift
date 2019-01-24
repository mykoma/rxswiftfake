//
//  Bag.swift
//  RxSwiftFake
//
//  Created by Gang on 2018/12/21.
//  Copyright © 2018 goluk. All rights reserved.
//

import Foundation

let arrayDictionaryMaxSize = 30

struct BagKey {
    
    fileprivate let rawValue: UInt64
    
}

struct Bag<T>: CustomDebugStringConvertible {
    
    typealias KeyType = BagKey
    
    typealias Entry = (key: BagKey, value: T)
    
    fileprivate var _nextKey: BagKey = BagKey(rawValue: 0)
    
    var _key0: BagKey? = nil
    var _value0: T? = nil
    
    var _pairs = ContiguousArray<Entry>()
    
    var _dictionary: [BagKey: T]? = nil
    
    var _onlyFastPath = true
    
    init() { }
    
    mutating func insert(_ element: T) -> BagKey {
        let key = _nextKey
        
        _nextKey = BagKey(rawValue: _nextKey.rawValue &+ 1)
        
        // 把第一个元素，放在自己的_key0和_value0中保存
        if _key0 == nil {
            _key0 = key
            _value0 = element
            return key
        }
        
        _onlyFastPath = false
        
        // 如果 _dictionary 不为 nil，那么设置到_dictionary
        if var dict = _dictionary {
            dict[key] = element
            return key
        }
        
        // _pairs有一个默认数组，但是最多只能存放30个
        if _pairs.count < arrayDictionaryMaxSize {
            _pairs.append((key: key, value: element))
            return key
        }
        
        // 如果_pairs存满了，那么根据key和element生成_dictionary
        _dictionary = [key: element]
        return key
    }
    
    var count: Int {
        let dictionaryCount: Int = _dictionary?.count ?? 0
        return (_value0 != nil ? 1 : 0) + _pairs.count + dictionaryCount
    }
    
    mutating func removeAll() {
        _key0 = nil
        _value0 = nil
        
        _pairs.removeAll(keepingCapacity: false)
        _dictionary?.removeAll(keepingCapacity: false)
    }
    
    mutating func removeKey(_ key: BagKey) -> T? {
        if _key0 == key {
            _key0 = nil
            let value = _value0
            _value0 = nil
            return value
        }
        if let existingObject = _dictionary?.removeValue(forKey: key) {
            return existingObject
        }
        for i in 0 ..< _pairs.count {
            if _pairs[i].key == key {
                let value = _pairs[i].value
                _pairs.remove(at: i)
                return value
            }
        }
        
        return nil
    }
}

extension Bag {
    
    var debugDescription: String {
        return "\(self.count) elements in Bag"
    }
    
}

extension BagKey: Hashable {
    
    var hashValue: Int {
        return rawValue.hashValue
    }
    
}

func ==(lhs: BagKey, rhs: BagKey) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
