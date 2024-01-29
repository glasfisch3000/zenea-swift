import Foundation
import Crypto
import utils

public struct Block: Identifiable, Hashable {
    public struct ID: Hashable {
        public enum Algorithm: String, Hashable {
            case sha2_256 = "sha2-256"
        }
        
        public var algorithm: Algorithm
        public var hash: [UInt8]
    }
    
    public var id: Self.ID
    public var content: Data
    
    public init(id: Self.ID? = nil, content: Data) {
        self.content = content
        
        if let id = id {
            self.id = id
        } else {
            var hasher = SHA256()
            hasher.update(data: content)
            
            let hash = hasher.finalize()
            self.id = .init(algorithm: .sha2_256, hash: hash.map { $0 })
        }
    }
}

extension Block.ID.Algorithm {
    public init?(parsing string: String) {
        switch string {
        case "sha2-256", "sha2_256", "sha-256", "sha_256", "sha256": self = .sha2_256
        default: return nil
        }
    }
}

extension Block.ID: CustomStringConvertible {
    fileprivate static let _blockIDPattern = try! Regex("(?<algorithm>sha2?-256|sha256)-(?<hash>[A-Fa-f0-9]+)")
    
    public init?(parsing string: String) {
        guard let match = string.wholeMatch(of: Self._blockIDPattern) else { return nil }
        
        guard let algorithmSubstring = match["algorithm"]?.substring else { return nil }
        guard let algorithm = Algorithm(parsing: String(algorithmSubstring)) else { return nil }
        self.algorithm = algorithm
        
        guard let hashSubstring = match["hash"]?.substring else { return nil }
        guard let hash = [UInt8](hexString: String(hashSubstring)) else { return nil }
        self.hash = hash
        
        switch algorithm {
        case .sha2_256: if hash.count != SHA256.Digest.byteCount { return nil }
        }
    }
    
    public var description: String {
        self.algorithm.rawValue + "-" + self.hash.toHexString()
    }
}

extension Block {
    public func matchesID(_ id: ID) -> Bool {
        switch id.algorithm {
        case .sha2_256:
            var hasher = SHA256()
            hasher.update(data: self.content)
            
            let hash = hasher.finalize()
            return id.hash.elementsEqual(hash)
        }
    }
}