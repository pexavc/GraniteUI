import Foundation

public func identify(_ item: Any) -> String {
    return "\(item.self)"
}

public func identifyPrefix(_ item: Any) -> String {
    return String(identify(item).prefix(12))
}


public class Instance {
    let name: String
    let uuid: UUID
    public init(name: String) {
        self.name = name
        self.uuid = .init()
    }
}

public protocol ID {
    var id: ObjectIdentifier { get }
}

extension ID {
    public var instance: Instance {
        Instance.init(name: "\(String(describing: Self.self))")
    }
}

extension ID  {
    public var id: ObjectIdentifier {
        return ObjectIdentifier(Self.self)
    }
    
    public var idHash: Int {
        return id.hashValue
    }
    
    public func isEqual(to: ID) -> Bool {
        return self.id == to.id && identify(self) == identify(to)
    }
    
    public func isNotEqual(to: ID) -> Bool {
        return !isEqual(to: to)
    }
    
    public var uuid: UUID {
        instance.uuid
    }
    
    public var mem: Int {
        MemoryLayout.size(ofValue: Self.self)
    }
    
    public var memID: Int {
        mem
    }
}
