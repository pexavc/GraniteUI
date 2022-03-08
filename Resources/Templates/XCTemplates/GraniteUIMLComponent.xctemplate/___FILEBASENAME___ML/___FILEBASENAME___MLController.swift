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

public class ___VARIABLE_productName___MLController: GraniteController<___VARIABLE_productName___MLState, ___VARIABLE_productName___MLView> {
    
    public override var load: ___VARIABLE_productName___MLView? {
        ___VARIABLE_productName___MLView.init(component: component)
    }
}

public struct ___VARIABLE_productName___MLView: GraniteView {
    @ObservedObject internal var component: Component<___VARIABLE_productName___MLState, Self>
    
    public var event: Event?
    public var responder: EventResponder?

    public var body: some View {
        EmptyView.init()
    }
}
