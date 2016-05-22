//
//  Scene1ViewModel.swift
//  MVVM
//
//  Created by Xavier on 08/04/16.
//  Copyright © 2016 XL Software Solutions
//

// KEYPOINT 4

// - View Model belong to the Data Model hierarchy, and are always instantiated
// - View Models have 3 sections
//
// Input Section
//     1: Update Data Model
//     2: Update Context Mgr and Trigger UI Refresh
//
// Refresh Section:
//     Update matching VC if present
//
// Accessor:
//     Process read request toward DataModel and/or Context Mgr
//
// Remark: there is a 1 to 1 relationship between View Model and View Controller
// Maintained by weak reference on both sides
// I don't use protocol because it is extra lines with little gain because of this 1 to 1 relationship.

import Foundation
import AppKit

class Scene1ViewModel: GenericViewModel
{
    // Generic View Model
    init(dataModel : DataModel, viewController: Scene1ViewController)
    {
        super.init(dataModel: dataModel, owner: viewController)
    }


    // MARK: - Input Processing
    // 1: First update data model variable without UI refresh
    // 2: Then update context variable with UI Refresh

    func updateValue(numberStr: String, focus: NSObject?)
    {

        let formatter = NSNumberFormatter()
        if let val = formatter.numberFromString(numberStr)?.integerValue
        {
            updateActionAndRefresh(owner: owner) {
                dataModel.observedSelf.number1 = val
                contextMgr.currentFocus = focus
            }
        } else {
            NSBeep()
        }
    }

    func toggleLeftView()
    {
        updateActionAndRefresh(owner: owner) {
            contextMgr.toggleLeftView()
        }
    }

    func toggleRightView()
    {
        updateActionAndRefresh(owner: owner) {
            contextMgr.toggleRightView()
        }
    }

    func toggleTransientAndRefresh()
    {
        updateActionAndRefresh(owner: owner) {
            if let _ = self.dataModel.transientClass {
                print("Removing Transient")
                dataModel.removeTransient()
            } else {
                print("Creating Transient")
                dataModel.createTransient()
            }
        }
    }

    func transientAddtoArray()
    {
        updateActionAndRefresh(owner: owner) {
            let value = dataModel.number1
            dataModel.transientClass?.arrayVal[0].intValue += value
        }
    }


    // MARK: - Get Data Model - Read Only request

    //MARK: getFocus
    static func getFocusKeypath() -> Set<KeypathDescription>
    {
        let keypathDescription = KeypathDescription(root: ContextMgr.contextMgrK, chain: [ContextMgr.currentFocusK])
        return [keypathDescription]
    }

    func getFocus() -> NSObject? {
        let value = contextMgr.observed.currentFocus
        return value
    }

    //MARK: getValue1
    static func getValue1Keypaths() -> Set<KeypathDescription>
    {
        let keypathDescription = KeypathDescription(root:DataModel.dataModelK, chain: [DataModel.number1K])
        return [keypathDescription]
    }

    var value1: String {
        get {
            let formatter = NSNumberFormatter()
            let val = dataModel.observedSelf.number1
            return  formatter.stringFromNumber(val) ?? "Error"
        }
    }

    //MARK: getSum
    static func getInvSumKeypaths() -> Set<KeypathDescription>
    {
        let keypathDescription = KeypathDescription(root:DataModel.dataModelK, chain: [DataModel.invSumOfNumberK])
        return [keypathDescription]
    }

    func getInvSum() -> Int?
    {
        return dataModel.observedSelf.invSumOfNumber
    }

    //MARK: getArraySum
    static func getArraySumKeypaths() -> Set<KeypathDescription>
    {
        let keypathDescription = KeypathDescription(root:DataModel.dataModelK,
                        chain: [DataModel.transientClassK, TransientClass.arrayValueK, NodeObjc.intValueK()])
        return [keypathDescription]
    }

    func getArraySum() -> Int?
    {
        return dataModel.observedSelf.transientClass?.arrayVal.map({$0.intValue}).reduce(0, combine: +)
    }

    //MARK: getTransient
    static func getTransientKeypaths() -> Set<KeypathDescription>
    {
        let keypathDescription = KeypathDescription(root:DataModel.dataModelK, chain: [DataModel.transientClassK, TransientClass.transientValK])
        return [keypathDescription]
    }

    func getTransient() -> String?
    {
        if let transient = dataModel.observedSelf.transientClass {
            let val = transient.transientVal
            return val
        }
        return nil
    }

}