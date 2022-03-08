//
//  GraniteDebug.swift
//
//
//  Created by 0xZala on 2/26/21.
//

import Foundation
import SwiftUI

public struct GraniteDebug: View {
    
    public init(_ message: String) {
        GraniteLogger.info("[GraniteDebugView] \(message)", focus: true)
    }
    
    public var body: some View {
        EmptyView().hidden()
    }
}
