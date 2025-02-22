//
//  EthereumTransaction.swift
//  Web3
//
//  Created by Koray Koska on 05.02.18.
//  Copyright © 2018 Boilertalk. All rights reserved.
//

import Foundation
import BigInt

/// Legacy (0xC0) transaction
public struct EthereumTransaction: Codable {
    /// The number of transactions made prior to this one
    public var nonce: EthereumQuantity?
    
    /// Gas price provided Wei
    public var gasPrice: EthereumQuantity?
    
    /// Gas limit provided
    public var gas: EthereumQuantity?
    
    /// Address of the sender
    public var from: EthereumAddress?
    
    /// Address of the receiver
    public var to: EthereumAddress?
    
    /// Value to transfer provided in Wei
    public var value: EthereumQuantity?
    
    /// Input data for this transaction
    public var data: EthereumData
    
    // MARK: - Initialization
    
    /**
     * Initializes a new instance of `EthereumTransaction` with the given values.
     *
     * - parameter nonce: The nonce of this transaction.
     * - parameter gasPrice: The gas price for this transaction in wei.
     * - parameter gasLimit: The gas limit for this transaction.
     * - parameter from: The address to send from, required to send a transaction using sendTransaction()
     * - parameter to: The address of the receiver.
     * - parameter value: The value to be sent by this transaction in wei.
     * - parameter data: Input data for this transaction. Defaults to [].
     */
    public init(
        nonce: EthereumQuantity? = nil,
        gasPrice: EthereumQuantity? = nil,
        gas: EthereumQuantity? = nil,
        from: EthereumAddress? = nil,
        to: EthereumAddress? = nil,
        value: EthereumQuantity? = nil,
        data: EthereumData = EthereumData([])
    ) {
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gas = gas
        self.from = from
        self.to = to
        self.value = value
        self.data = data
    }
    
    // MARK: - Convenient functions
    
    /**
     * Signs this transaction with the given private key and returns an instance of `EthereumSignedTransaction`
     *
     * - parameter privateKey: The private key for the new signature.
     * - parameter chainId: chainId as described in EIP155.
     */
    public func sign(with privateKey: EthereumPrivateKey, chainId: EthereumQuantity) throws -> EthereumSignedTransaction {
        let rawRlp = try rawRLP(chainID: chainId)
        let signature = try privateKey.sign(message: rawRlp)
        return try signedTransaction(signature: signature, chainID: chainId)
    }
    
    public func rawRLP(chainID: EthereumQuantity) throws -> Bytes {
        guard let nonce = nonce, let gasPrice = gasPrice, let gasLimit = gas, let value = value else {
            throw EthereumTransactionError.transactionInvalid
        }
        let rlp = RLPItem(
            nonce: nonce,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            to: to,
            value: value,
            data: data,
            v: chainID,
            r: 0,
            s: 0
        )
        return try RLPEncoder().encode(rlp)
    }
    
    public func signedTransaction(
        signature: (v: UInt, r: Bytes, s: Bytes),
        chainID: EthereumQuantity
    ) throws -> EthereumSignedTransaction {
        guard let nonce = nonce, let gasPrice = gasPrice, let gasLimit = gas, let value = value else {
            throw EthereumTransactionError.transactionInvalid
        }
        
        let v: BigUInt
        if chainID.quantity == 0 {
            v = BigUInt(signature.v) + BigUInt(27)
        } else {
            let sigV = BigUInt(signature.v)
            let big27 = BigUInt(27)
            let chainIdCalc = (chainID.quantity * BigUInt(2) + BigUInt(8))
            v = sigV + big27 + chainIdCalc
        }
        
        let r = BigUInt(signature.r)
        let s = BigUInt(signature.s)
        
        return EthereumSignedTransaction(
            nonce: nonce,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            to: to,
            value: value,
            data: data,
            v: EthereumQuantity(quantity: v),
            r: EthereumQuantity(quantity: r),
            s: EthereumQuantity(quantity: s),
            chainId: chainID
        )
    }
}

public struct EthereumSignedTransaction {

    // MARK: - Properties

    /// The number of transactions made prior to this one
    public let nonce: EthereumQuantity

    /// Gas price provided Wei
    public let gasPrice: EthereumQuantity

    /// Gas limit provided
    public let gasLimit: EthereumQuantity

    /// Address of the receiver
    public let to: EthereumAddress?

    /// Value to transfer provided in Wei
    public let value: EthereumQuantity

    /// Input data for this transaction
    public let data: EthereumData

    /// EC signature parameter v
    public let v: EthereumQuantity

    /// EC signature parameter r
    public let r: EthereumQuantity

    /// EC recovery ID
    public let s: EthereumQuantity

    /// EIP 155 chainId. Mainnet: 1
    public let chainId: EthereumQuantity

    // MARK: - Initialization

    /**
     * Initializes a new instance of `EthereumSignedTransaction` with the given values.
     *
     * - parameter nonce: The nonce of this transaction.
     * - parameter gasPrice: The gas price for this transaction in wei.
     * - parameter gasLimit: The gas limit for this transaction.
     * - parameter to: The address of the receiver.
     * - parameter value: The value to be sent by this transaction in wei.
     * - parameter data: Input data for this transaction.
     * - parameter v: EC signature parameter v.
     * - parameter r: EC signature parameter r.
     * - parameter s: EC recovery ID.
     * - parameter chainId: The chainId as described in EIP155. Mainnet: 1.
     *                      If set to 0 and v doesn't contain a chainId,
     *                      old style transactions are assumed.
     */
    public init(
        nonce: EthereumQuantity,
        gasPrice: EthereumQuantity,
        gasLimit: EthereumQuantity,
        to: EthereumAddress?,
        value: EthereumQuantity,
        data: EthereumData,
        v: EthereumQuantity,
        r: EthereumQuantity,
        s: EthereumQuantity,
        chainId: EthereumQuantity
    ) {
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
        self.v = v
        self.r = r
        self.s = s

        if chainId.quantity == 0 && v.quantity >= 37 {
            if v.quantity % 2 == 0 {
                self.chainId = EthereumQuantity(quantity: (v.quantity - 36) / 2)
            } else {
                self.chainId = EthereumQuantity(quantity: (v.quantity - 35) / 2)
            }
        } else {
            self.chainId = chainId
        }
    }
    
    // MARK: - Convenient functions

    public func verifySignature() -> Bool {
        let recId: BigUInt
        if v.quantity >= BigUInt(35) + (BigUInt(2) * chainId.quantity) {
            recId = v.quantity - BigUInt(35) - (BigUInt(2) * chainId.quantity)
        } else {
            if v.quantity >= 27 {
                recId = v.quantity - 27
            } else {
                recId = v.quantity
            }
        }
        let rlp = RLPItem(
            nonce: nonce,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            to: to,
            value: value,
            data: data,
            v: chainId,
            r: 0,
            s: 0
        )
        if let _ = try? EthereumPublicKey(message: RLPEncoder().encode(rlp), v: EthereumQuantity(quantity: recId), r: r, s: s) {
            return true
        }

        return false
    }
}

private extension RLPItem {
    /**
     * Create an RLPItem representing a transaction. The RLPItem must be an array of 9 items in the proper order.
     *
     * - parameter nonce: The nonce of this transaction.
     * - parameter gasPrice: The gas price for this transaction in wei.
     * - parameter gasLimit: The gas limit for this transaction.
     * - parameter to: The address of the receiver.
     * - parameter value: The value to be sent by this transaction in wei.
     * - parameter data: Input data for this transaction.
     * - parameter v: EC signature parameter v, or a EIP155 chain id for an unsigned transaction.
     * - parameter r: EC signature parameter r.
     * - parameter s: EC recovery ID.
     */
    init(
        nonce: EthereumQuantity,
        gasPrice: EthereumQuantity,
        gasLimit: EthereumQuantity,
        to: EthereumAddress?,
        value: EthereumQuantity,
        data: EthereumData,
        v: EthereumQuantity,
        r: EthereumQuantity,
        s: EthereumQuantity
    ) {
        self = .array(
            .bigUInt(nonce.quantity),
            .bigUInt(gasPrice.quantity),
            .bigUInt(gasLimit.quantity),
            .bytes(to?.rawAddress ?? Bytes()),
            .bigUInt(value.quantity),
            .bytes(data.bytes),
            .bigUInt(v.quantity),
            .bigUInt(r.quantity),
            .bigUInt(s.quantity)
        )
    }
    
}

extension EthereumSignedTransaction: RLPItemConvertible {

    public init(rlp: RLPItem) throws {
        guard let array = rlp.array, array.count == 9 else {
            throw EthereumTransactionError.rlpItemInvalid
        }
        guard let nonce = array[0].bigUInt, let gasPrice = array[1].bigUInt, let gasLimit = array[2].bigUInt,
            let toBytes = array[3].bytes, let to = try? EthereumAddress(rawAddress: toBytes),
            let value = array[4].bigUInt, let data = array[5].bytes, let v = array[6].bigUInt,
            let r = array[7].bigUInt, let s = array[8].bigUInt else {
                throw EthereumTransactionError.rlpItemInvalid
        }

        self.init(
            nonce: EthereumQuantity(quantity: nonce),
            gasPrice: EthereumQuantity(quantity: gasPrice),
            gasLimit: EthereumQuantity(quantity: gasLimit),
            to: to,
            value: EthereumQuantity(quantity: value),
            data: EthereumData(data),
            v: EthereumQuantity(quantity: v),
            r: EthereumQuantity(quantity: r),
            s: EthereumQuantity(quantity: s),
            chainId: 0
        )
    }

    public func rlp() -> RLPItem {
        return RLPItem(
            nonce: nonce,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            to: to,
            value: value,
            data: data,
            v: v,
            r: r,
            s: s
        )
    }
}

extension EthereumSignedTransaction: RawTransactionConvertible {
    public func rawTransaction() -> String {
        let encoder = RLPEncoder()
        let payload = rlp()
        let rawTx = try? encoder.encode(payload).hexString(prefix: true)
        return rawTx ?? "0x"
    }
}

// MARK: - Equatable

extension EthereumTransaction: Equatable {
    public static func ==(_ lhs: EthereumTransaction, _ rhs: EthereumTransaction) -> Bool {
        return lhs.nonce == rhs.nonce
            && lhs.gasPrice == rhs.gasPrice
            && lhs.gas == rhs.gas
            && lhs.from == rhs.from
            && lhs.to == rhs.to
            && lhs.value == rhs.value
            && lhs.data == rhs.data
    }
}

extension EthereumSignedTransaction: Equatable {

    public static func ==(_ lhs: EthereumSignedTransaction, _ rhs: EthereumSignedTransaction) -> Bool {
        return lhs.nonce == rhs.nonce
            && lhs.gasPrice == rhs.gasPrice
            && lhs.gasLimit == rhs.gasLimit
            && lhs.to == rhs.to
            && lhs.value == rhs.value
            && lhs.data == rhs.data
            && lhs.v == rhs.v
            && lhs.r == rhs.r
            && lhs.s == rhs.s
            && lhs.chainId == rhs.chainId
    }
}

// MARK: - Hashable

extension EthereumTransaction: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(nonce)
        hasher.combine(gasPrice)
        hasher.combine(gas)
        hasher.combine(from)
        hasher.combine(to)
        hasher.combine(value)
        hasher.combine(data)
    }
}

extension EthereumSignedTransaction: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(nonce)
        hasher.combine(gasPrice)
        hasher.combine(gasLimit)
        hasher.combine(to)
        hasher.combine(value)
        hasher.combine(data)
        hasher.combine(v)
        hasher.combine(r)
        hasher.combine(s)
        hasher.combine(chainId)
    }
}
