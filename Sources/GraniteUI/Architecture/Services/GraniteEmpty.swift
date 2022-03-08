//
//  GraniteEmpty.swift
//
//
//  Created by 0xZala on 2/26/21.
//

import Foundation

public protocol GraniteEmpty {
    var isDependancyEmpty: Bool { get }
    var emptyText: String { get }
    var emptyPayload: GranitePayload? { get }
}
