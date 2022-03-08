//
//  GraniteAction.swift
//
//
//  Created by 0xZala on 2/11/21.
//

import Foundation
import SwiftUI

public struct GraniteAction: View {
    
    public init(_ connection: GraniteConnection,
                _ action: (() -> Void)? = nil,
                event: GraniteEvent? = nil) {
        
        if let theEvent = event {
            connection.request(theEvent)
        }
        action?()
    }
    
    public var body: some View {
        EmptyView().hidden()
    }
}
