//
//  Quantwm.swift
//  Quantwm_Example
//
//  Created by Xavier Lasne on 06/01/2018.
//  License MIT.
//

import Foundation
import Quantwm

class Mediator: QWMediator {
    func registerRoot(model: DataModel, rootProperty: QWRootProperty) {
        super.registerRoot(model: model, rootProperty: rootProperty)
    }

    func getRoot() -> DataModel? {
        return super.getRoot() as? DataModel
    }
}

protocol GetMediator {
    var qwMediator: Mediator { get }
}

extension GetMediator {

    // If from NSDocument, retrieve it from the Document, or the Model hierarchy, or from the View Hierarchy
    var qwMediator: Mediator {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.qwMediator
    }
}

class ViewModel: QWViewModel<Mediator> {

    // The forceUnwrap depends on your architecture
    // If model is never changing,
    // or if model change is performed inside an updateTransaction
    // (recommended for MacOS version browser)
    // then this is safe
    var dataModel: DataModel {
        return qwMediator.getRoot()!
    }
}




