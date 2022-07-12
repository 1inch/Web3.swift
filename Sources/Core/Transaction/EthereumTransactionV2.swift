//
//  EthereumTransactionV2.swift
//  Web3
//
//  Created by Andrew Podkovyrin on 17.07.21.
//  Copyright © 2021 1inch. All rights reserved.
//

import Foundation
import BigInt

/// EIP-1559 (0x02) transaction.
///
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md
public struct EthereumTransactionV2: Codable {
    /// The number of transactions made prior to this one
    public var nonce: EthereumQuantity?
    
    /// Max Priority Fee Per Gas (wei).
    /// Max amount for miner.
    public var maxPriorityFeePerGas: EthereumQuantity?

    /// Max Fee Per Gas (wei).
    /// Max amount for transaction (miner fee + base fee).
    public var maxFeePerGas: EthereumQuantity?
    
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
     * Initializes a new instance of `EthereumTransactionV2` with the given values.
     *
     * - parameter nonce: The nonce of this transaction.
     * - parameter maxPriorityFeePerGas: The max amount of gas to pay to the miner in wei.
     * - parameter maxFeePerGas: The max amount of gas to pay (both for miner and base fee) in wei.
     * - parameter gasLimit: The gas limit for this transaction.
     * - parameter from: The address to send from, required to send a transaction using sendTransaction()
     * - parameter to: The address of the receiver.
     * - parameter value: The value to be sent by this transaction in wei.
     * - parameter data: Input data for this transaction. Defaults to [].
     */
    public init(
        nonce: EthereumQuantity? = nil,
        maxPriorityFeePerGas: EthereumQuantity? = nil,
        maxFeePerGas: EthereumQuantity? = nil,
        gas: EthereumQuantity? = nil,
        from: EthereumAddress? = nil,
        to: EthereumAddress? = nil,
        value: EthereumQuantity? = nil,
        data: EthereumData = EthereumData([])
    ) {
        self.nonce = nonce
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.maxFeePerGas = maxFeePerGas
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
    public func sign(with privateKey: EthereumPrivateKey, chainId: EthereumQuantity) throws -> EthereumSignedTransactionV2 {
        let rawRLP = try rawRLP(chainID: chainId)
        let signature = try privateKey.sign(message: rawRLP)
        return try signedTransaction(signature: signature, chainID: chainId)
    }
    
    public func rawRLP(chainID: EthereumQuantity) throws -> Bytes {
        // These values are required for signing
        guard
            let nonce = nonce,
            let maxPriorityFeePerGas = maxPriorityFeePerGas,
            let maxFeePerGas = maxFeePerGas,
            let gasLimit = gas,
            let value = value
        else {
            throw EthereumTransactionError.transactionInvalid
        }

        let rlp = RLPItem(
            chainId: chainID,
            nonce: nonce,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            maxFeePerGas: maxFeePerGas,
            gasLimit: gasLimit,
            to: to,
            value: value,
            data: data
        )
        var rawRLP = try RLPEncoder().encode(rlp)
        rawRLP.insert(0x02, at: 0) // TransactionType
        return rawRLP
    }
    
    public func signedTransaction(
        signature: (v: UInt, r: Bytes, s: Bytes),
        chainID: EthereumQuantity
    ) throws -> EthereumSignedTransactionV2 {
        // These values are required for signing
        guard
            let nonce = nonce,
            let maxPriorityFeePerGas = maxPriorityFeePerGas,
            let maxFeePerGas = maxFeePerGas,
            let gasLimit = gas,
            let value = value
        else {
            throw EthereumTransactionError.transactionInvalid
        }
        
        let v = BigUInt(signature.v)
        let r = BigUInt(signature.r)
        let s = BigUInt(signature.s)

        return EthereumSignedTransactionV2(
            nonce: nonce,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            maxFeePerGas: maxFeePerGas,
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

public struct EthereumSignedTransactionV2 {

    // MARK: - Properties

    /// The number of transactions made prior to this one
    public let nonce: EthereumQuantity

    /// Max Priority Fee Per Gas (wei).
    /// Max amount for miner.
    public let maxPriorityFeePerGas: EthereumQuantity

    /// Max Fee Per Gas (wei).
    /// Max amount for transaction (miner fee + base fee).
    public let maxFeePerGas: EthereumQuantity

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
     * - parameter maxPriorityFeePerGas: The max amount of gas to pay to the miner in wei.
     * - parameter maxFeePerGas: The max amount of gas to pay (both for miner and base fee) in wei.
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
        maxPriorityFeePerGas: EthereumQuantity,
        maxFeePerGas: EthereumQuantity,
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
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.maxFeePerGas = maxFeePerGas
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
        self.v = v
        self.r = r
        self.s = s
        self.chainId = chainId
    }
    
    // MARK: - Convenient functions

    public func verifySignature() -> Bool {
        let recId = v.quantity
        let rlp = RLPItem(
            chainId: chainId,
            nonce: nonce,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            maxFeePerGas: maxFeePerGas,
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

extension RLPItem {
    /**
     * Create an RLPItem representing a transaction. The RLPItem must be an array of 11 items in the proper order.
     *
     * - parameter chainId: The chain id of this transaction.
     * - parameter nonce: The nonce of this transaction.
     * - parameter maxPriorityFeePerGas: The max amount of gas to pay to the miner in wei.
     * - parameter maxFeePerGas: The max amount of gas to pay (both for miner and base fee) in wei.
     * - parameter to: The address of the receiver.
     * - parameter value: The value to be sent by this transaction in wei.
     * - parameter data: Input data for this transaction.
     * - parameter v: EC signature parameter v.
     * - parameter r: EC signature parameter r.
     * - parameter s: EC recovery ID.
     */
    init(
        chainId: EthereumQuantity,
        nonce: EthereumQuantity,
        maxPriorityFeePerGas: EthereumQuantity,
        maxFeePerGas: EthereumQuantity,
        gasLimit: EthereumQuantity,
        to: EthereumAddress?,
        value: EthereumQuantity,
        data: EthereumData,
        v: EthereumQuantity,
        r: EthereumQuantity,
        s: EthereumQuantity
    ) {
        self = .array(
            .bigUInt(chainId.quantity),
            .bigUInt(nonce.quantity),
            .bigUInt(maxPriorityFeePerGas.quantity),
            .bigUInt(maxFeePerGas.quantity),
            .bigUInt(gasLimit.quantity),
            .bytes(to?.rawAddress ?? Bytes()),
            .bigUInt(value.quantity),
            .bytes(data.bytes),
            .array(), // empty access_list
            .bigUInt(v.quantity),
            .bigUInt(r.quantity),
            .bigUInt(s.quantity)
        )
    }

    /**
     * Create an RLPItem representing a transaction. The RLPItem must be an array of 9 items in the proper order.
     *
     * - parameter chainId: The chain id of this transaction.
     * - parameter nonce: The nonce of this transaction.
     * - parameter maxPriorityFeePerGas: The max amount of gas to pay to the miner in wei.
     * - parameter maxFeePerGas: The max amount of gas to pay (both for miner and base fee) in wei.
     * - parameter to: The address of the receiver.
     * - parameter value: The value to be sent by this transaction in wei.
     * - parameter data: Input data for this transaction.
     */
    init(
        chainId: EthereumQuantity,
        nonce: EthereumQuantity,
        maxPriorityFeePerGas: EthereumQuantity,
        maxFeePerGas: EthereumQuantity,
        gasLimit: EthereumQuantity,
        to: EthereumAddress?,
        value: EthereumQuantity,
        data: EthereumData
    ) {
        self = .array(
            .bigUInt(chainId.quantity),
            .bigUInt(nonce.quantity),
            .bigUInt(maxPriorityFeePerGas.quantity),
            .bigUInt(maxFeePerGas.quantity),
            .bigUInt(gasLimit.quantity),
            .bytes(to?.rawAddress ?? Bytes()),
            .bigUInt(value.quantity),
            .bytes(data.bytes),
            .array() // empty access_list
        )
    }
}

extension EthereumSignedTransactionV2: RLPItemConvertible {

    public init(rlp: RLPItem) throws {
        guard let array = rlp.array, array.count == 11 else {
            throw EthereumTransactionError.rlpItemInvalid
        }
        guard
            let chainId = array[0].bigUInt,
            let nonce = array[1].bigUInt,
            let maxPriorityFeePerGas = array[2].bigUInt,
            let maxFeePerGas = array[3].bigUInt,
            let gasLimit = array[4].bigUInt,
            let toBytes = array[5].bytes,
            let to = try? EthereumAddress(rawAddress: toBytes),
            let value = array[6].bigUInt,
            let data = array[7].bytes,
            // skip access list: array[8]
            let v = array[9].bigUInt,
            let r = array[10].bigUInt,
            let s = array[11].bigUInt
        else {
            throw EthereumTransactionError.rlpItemInvalid
        }

        self.init(
            nonce: EthereumQuantity(quantity: nonce),
            maxPriorityFeePerGas: EthereumQuantity(quantity: maxPriorityFeePerGas),
            maxFeePerGas: EthereumQuantity(quantity: maxFeePerGas),
            gasLimit: EthereumQuantity(quantity: gasLimit),
            to: to,
            value: EthereumQuantity(quantity: value),
            data: EthereumData(data),
            v: EthereumQuantity(quantity: v),
            r: EthereumQuantity(quantity: r),
            s: EthereumQuantity(quantity: s),
            chainId: EthereumQuantity(quantity: chainId)
        )
    }

    public func rlp() -> RLPItem {
        return RLPItem(
            chainId: chainId,
            nonce: nonce,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            maxFeePerGas: maxFeePerGas,
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

extension EthereumSignedTransactionV2: RawTransactionConvertible {
    public func rawTransaction() -> String {
        let encoder = RLPEncoder()
        let payload = rlp()
        let rawPayload = (try? encoder.encode(payload).hexString(prefix: false)) ?? ""
        let rawTx = "0x02\(rawPayload)" // must include transaction type prefix
        return rawTx
    }
}

// MARK: - Equatable

extension EthereumTransactionV2: Equatable {
    public static func ==(_ lhs: EthereumTransactionV2, _ rhs: EthereumTransactionV2) -> Bool {
        return lhs.nonce == rhs.nonce
            && lhs.maxPriorityFeePerGas == rhs.maxPriorityFeePerGas
            && lhs.maxFeePerGas == rhs.maxFeePerGas
            && lhs.gas == rhs.gas
            && lhs.from == rhs.from
            && lhs.to == rhs.to
            && lhs.value == rhs.value
            && lhs.data == rhs.data
    }
}

extension EthereumSignedTransactionV2: Equatable {

    public static func ==(_ lhs: EthereumSignedTransactionV2, _ rhs: EthereumSignedTransactionV2) -> Bool {
        return lhs.nonce == rhs.nonce
            && lhs.maxPriorityFeePerGas == rhs.maxPriorityFeePerGas
            && lhs.maxFeePerGas == rhs.maxFeePerGas
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

extension EthereumTransactionV2: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(nonce)
        hasher.combine(maxPriorityFeePerGas)
        hasher.combine(maxFeePerGas)
        hasher.combine(gas)
        hasher.combine(from)
        hasher.combine(to)
        hasher.combine(value)
        hasher.combine(data)
    }
}

extension EthereumSignedTransactionV2: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(nonce)
        hasher.combine(maxPriorityFeePerGas)
        hasher.combine(maxFeePerGas)
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
