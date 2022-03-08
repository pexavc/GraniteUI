//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright (c) ___YEAR___ Stoic Collective, LLC.. All rights reserved.
//

import GraniteUI
import SwiftUI
import Combine
import Metal
import CoreML

public struct ___VARIABLE_productName___MLBuilder {
    static public var main: some View {
        ___VARIABLE_productName___MLBuilder.build(.init(___VARIABLE_productName___Model.self)).controller?.render
    }
    
    static public func build(
        _ state: ___VARIABLE_productName___MLState,
        _ service: Service = ServiceCenter.init()) -> Component<___VARIABLE_productName___MLState, ___VARIABLE_productName___MLView> {

        return ___VARIABLE_productName___MLController.init(___VARIABLE_productName___MLComponent.init(state, service)).component
    }
}
