//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright (c) ___YEAR___ Stoic Collective, LLC.. All rights reserved.
//

import Granite
import Foundation
import UIKit
import Metal
import CoreML

class ___VARIABLE_productName___MLBuilder {
    static func build(
        _ service: Service,
        parent: AnyComponent? = nil) -> ___VARIABLE_productName___MLComponent {
        return ___VARIABLE_productName___MLComponent(
            service,
            .init(___VARIABLE_productName___Model.self),
            parent: parent)
    }
}
