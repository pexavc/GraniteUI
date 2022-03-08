//
//  Local Storage.swift
//  Wrapper for UserDefaults, a swiftier approach in accessing and retrieving
//  of data meant for an applications basic lifecycle.
//
//  Created by 0xZala on 9/14/20.
//

import Foundation

open class LocalStorage {
    public static var defaults: UserDefaults {
        UserDefaults.standard
    }
    
    open class Value<T> {
        
        let key: String
        var data: T?
        
        public init(_ key: String, _ data: T?) {
            self.key = key
            self.data = data
            self.internalInit()
        }
        
        public init(_ data: T?) {
            
            if let lsv = data as? LocalStorageValue {
                self.key = lsv.key
            } else {
                self.key = ""
            }
            
            self.data = data
            
            internalInit()
        }
        
        private func internalInit() {
            if LocalStorage.isKeyPresentInUserDefaults(key: key) {
                self.data = retrieve()
            } else {
                self.update(data)
            }
            
        }
        
        public func retrieve() -> T? {
            if let lsv = data as? LocalStorageValue {
                if let rawInt = LocalStorage.defaults.object(forKey: key) as? Int {
                    return lsv.instance(of: rawInt) as? T
                } else {
                    return nil
                }
            } else {
                return LocalStorage.defaults.object(forKey: key) as? T
            }
        }
        
        public func update<V>(_ data: V? = nil) {
            if let lsv = data as? LocalStorageValue {
                LocalStorage.defaults.set(lsv.intValue ?? 0, forKey: key)
            } else if let data = data as? T {
                LocalStorage.defaults.set(data, forKey: key)
            }
            
            LocalStorage.defaults.synchronize()
            self.data = data as? T
        }
    }
    
    private var valuesAny: [Value<Any>]
    private var valuesLSV: [Value<LocalStorageValue>]
    
    public var directory: [String : Any] {
        var directoryToAdd: [String : Any] = [:]
        
        valuesAny.forEach { value in
            directoryToAdd[value.key] = value
        }
        
        valuesLSV.forEach { value in
            directoryToAdd[value.key] = value
        }
        
        return directoryToAdd
    }
    
    public init() {
        valuesAny = []
        valuesLSV = []
    }
    
    public func set(_ values: [Value<Any>]) {
        self.valuesAny = values
    }
    
    public func set(_ values: [Value<LocalStorageValue>]) {
        self.valuesLSV = values
    }
    
    public func append(_ values: [Value<Any>]) {
        self.valuesAny.append(contentsOf: values)
    }
    
    public func append(_ values: [Value<LocalStorageValue>]) {
        self.valuesLSV.append(contentsOf: values)
    }
    
    public func get<T>(_ key: Any, defaultValue: T) -> T {
        if let lsv = key as? LocalStorageValue {
            guard let value = directory.first(
                where: { $0.key == lsv.key })?.value as? (Value<LocalStorageValue>) else {
                return defaultValue
            }
            return (value.data as? T) ?? defaultValue
        }else if let ks = key as? String {
            guard let value = directory.first(
                where: { $0.key == ks })?.value as? (Value<Any>) else {
                return defaultValue
            }
            return (value.data as? T) ?? defaultValue
        } else {
            return defaultValue
        }
    }
    
    public func get(_ lsv: LocalStorageValue.Type) -> Int {
        guard let value = directory.first(
            where: { $0.key == lsv.key })?.value as? (Value<LocalStorageValue>) else {
            return -1
        }
        
        return (value.data)?.value ?? -1
    }
    
    public func getObject(_ lsv: LocalStorageValue.Type) -> LocalStorageValue? {
        guard let value = directory.first(
            where: { $0.key == lsv.key })?.value as? (Value<LocalStorageValue>) else {
            return nil
        }
        
        return value.data
    }
    
    public func store(_ value: Value<Any>) {
        if !directory.keys.contains(value.key) {
            valuesAny.append(value)
        }
    }
    
    public static func isKeyPresentInUserDefaults(key: String) -> Bool {
        return LocalStorage.defaults.object(forKey: key) != nil
    }
    
    public func assert<T: Equatable>(
        _ key: String,
        _ comparable: T) -> Bool {
        
        guard let value = directory.first(
            where: { $0.key == key })?.value as? (Value<Any>) else {
            return false
        }
        
        guard let data = value.data as? T else {
            return false
        }
        
        return data == comparable
    }
    
    public func assert(
        _ lsv: LocalStorageValue.Type,
        _ comparable: LocalStorageValue) -> Bool {
        
        guard let value = directory.first(
            where: { $0.key == lsv.key })?.value as? (Value<LocalStorageValue>) else {
            return false
        }
        
        return value.data?.value == comparable.value
    }
    
    public func update<T>(
        _ key: String,
        _ updatedValue: T) {
        
        guard let value = directory.first(
            where: { $0.key == key })?.value as? (Value<Any>) else {
            return
        }
        
        value.update(updatedValue)
    }
    
    public func update(
        _ lsv: LocalStorageValue) {
        
        guard let value = directory.first(
            where: { $0.key == lsv.key })?.value as? (Value<LocalStorageValue>) else {
            return
        }
        
        value.update(lsv)
    }
    
    public func clear() {
        UserDefaults.resetStandardUserDefaults()
        LocalStorage.defaults.synchronize()
    }
}

public enum LocalStorageReadWrite: Int {
    case read
    case write
    case readAndWrite
    case internalReadAndWrite
    case lock
    
    public var canWrite: Bool {
        return self == .write || self == .readAndWrite
    }
}

public enum LocalStorageResource {
    case image(String)
}

public protocol LocalStorageDefaults {
    static var defaults: [LocalStorage.Value<LocalStorageValue>] { get }
    var writeableDefaults: [LocalStorageValue] { get }
    var readableDefaults: [LocalStorageValue] { get }
    static var instance: LocalStorageDefaults { get }
    init()
}

extension LocalStorageDefaults {
    public var writeableDefaults: [LocalStorageValue] {
        return Self.defaults
            .compactMap({ $0.retrieve() })
            .filter({ $0.permissions.canWrite })
    }
    
    public var readableDefaults: [LocalStorageValue] {
        return Self.defaults
            .compactMap({ $0.retrieve() })
            .filter({ $0.permissions == .read || $0.permissions == .readAndWrite })
    }
    
    public static var instance: LocalStorageDefaults {
        Self.init()
    }
}

public protocol LocalStorageValue: Codable, CodingKey {
    var key: String { get }
    var value: Int { get }
    var resource: LocalStorageResource? { get }
    var asString: String { get }
    var description: String { get }
    var permissions: LocalStorageReadWrite { get }
    var allCases: [LocalStorageValue] { get }
    func instance(of: Int) -> Any?
}

extension LocalStorageValue {
    public var key: String {
        Self.key
    }
    
    public var asString: String {
        Self.key
    }
    
    public static var key: String {
        return "\(Self.self)"
    }
    
    public var description: String {
        return "\(Self.self)"
    }
    
    public var permissions: LocalStorageReadWrite {
        return .read
    }
    
    public var resource: LocalStorageResource? {
        nil
    }
}

extension LocalStorageValue where Self: RawRepresentable, Self.RawValue == Int {
    public func instance(of: Int) -> Any? {
        return Self.init(rawValue: of)
    }
}

extension LocalStorageValue where Self: Hashable {
    public static var allCases: [Self] {
        return [Self](AnySequence { () -> AnyIterator<Self> in
            var raw = 0
            var first: Self?
            return AnyIterator {
                let current = withUnsafeBytes(of: &raw) { $0.load(as: Self.self) }
                if raw == 0 {
                    first = current
                } else if current == first {
                    return nil
                }
                raw += 1
                return current
            }
        })
    }
    
    public var allCases: [LocalStorageValue] {
        return Self.allCases
   }
}
