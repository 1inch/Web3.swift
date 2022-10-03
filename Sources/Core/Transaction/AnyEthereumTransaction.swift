//
//  AnyEthereumTransaction.swift
//  OneInch
//
//  Created by Andrew Podkovyrin on 31.07.2021.
//

import Foundation

public enum AnyEthereumTransaction {
    case legacy(EthereumTransaction)
    case eip1559(EthereumTransactionV2)
}

extension AnyEthereumTransaction: Equatable {}

// MARK: Properties

public extension AnyEthereumTransaction {
    /// The number of transactions made prior to this one
    var nonce: EthereumQuantity? {
        switch self {
        case let .legacy(tx):
            return tx.nonce
        case let .eip1559(tx):
            return tx.nonce
        }
    }

    /// Gas limit provided
    var gas: EthereumQuantity? {
        switch self {
        case let .legacy(tx):
            return tx.gas
        case let .eip1559(tx):
            return tx.gas
        }
    }

    /// Address of the sender
    var from: EthereumAddress? {
        switch self {
        case let .legacy(tx):
            return tx.from
        case let .eip1559(tx):
            return tx.from
        }
    }

    /// Address of the receiver
    var to: EthereumAddress? {
        switch self {
        case let .legacy(tx):
            return tx.to
        case let .eip1559(tx):
            return tx.to
        }
    }

    /// Value to transfer provided in Wei
    var value: EthereumQuantity? {
        switch self {
        case let .legacy(tx):
            return tx.value
        case let .eip1559(tx):
            return tx.value
        }
    }

    /// Input data for this transaction
    var data: EthereumData {
        switch self {
        case let .legacy(tx):
            return tx.data
        case let .eip1559(tx):
            return tx.data
        }
    }
}

// MARK: Ethereum Call

public extension AnyEthereumTransaction {
    func asEthereumCall() -> EthereumCall? {
        switch self {
        case let .legacy(tx):
            guard let to = tx.to else { return nil }
            return EthereumCall(
                from: tx.from,
                to: to,
                gas: tx.gas,
                gasPrice: tx.gasPrice,
                value: tx.value,
                data: tx.data
            )
        case let .eip1559(tx):
            guard let to = tx.to else { return nil }
            return EthereumCall(
                from: tx.from,
                to: to,
                gas: tx.gas,
                maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
                maxFeePerGas: tx.maxFeePerGas,
                value: tx.value,
                data: tx.data
            )
        }
    }
}
