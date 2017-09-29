//
//  KeySetObserver.swift
//  QUANTWM
//
//  Created by Xavier Lasne on 15/04/16.
//  Copyright © 2016 XL Software Solutions. All rights reserved.
//

import Foundation

enum DataSetComparisonResult<T: Hashable>
{
  case error_WriteDataSetNotEmpty(Set<T>)
  case warning_ReadDataSetContainsMoreDataThanKeySetObserver(Set<T>)
  case info_ReadDataSetIsContainedIntoKeySetObserver(Set<T>)
  case info_TargetIsNil
  case identical
  case notDirty
}

class KeySetObserver: NSObject {
  
  enum TriggerState {
    case normal
    case created
    case updated(description: String)
    
    var description: String {
      switch self {
      case .normal:            return ""
      case .created:           return "Created"
      case .updated(let desc): return desc
      }
    }
    
    func isDirty() -> Bool {
      switch self {
      case .normal: return false
      default:      return true
      }
    }
  }
  
  // The target + Action: The method which will be called if dataset is dirty
  weak var target: NSObject?
  var targetAction: Selector
  let type: Any.Type  // used to detect multiple registration with the same type + selector
  
  // The set of keypath triggering this action
  // RepositoryObserver builds and updates the keypathObserverDict:[String : KeypathObserver] indexed by keypath
  // This set define the scheduling level of the KeySetObserver
  var keypathSet: Set<String>
  let schedulingLevel: Int
  
  // configurationSchedulingLevel defines if the KeySetObserver is of configuration type
  // and if not nil, its priority
  let configurationSchedulingLevel: Int?
  var isConfigurationType: Bool {
    return configurationSchedulingLevel != nil
  }
  
  // The set of PropertyDescription which can be written during the action
  // And enable exception to the write interdiction
  let writtenPropertySet: Set<String>
  
  // KeySetObserver name, for logging purpose
  let name: String
  
  // force dirty when TriggetDataSet is created or its keypathSet modified
  var forcedDirty = TriggerState.created
  var updateCounter: [String:Int] = [:]
  
  // Maintain the union of all the RW_Action which are actually read
  // in order to detect registration to unused actions
  // unionReadKeypathSet is composed only of PropertyDescription which are the result of the comparison between
  // configured and actual RW_Action, based on their common node.
  var unionReadKeypathSet: Set<String>
  
  //MARK: Init and update
  init(target: NSObject, selector: Selector, keypathSet: Set<String>,  name: String,
       schedulingLevel: Int, writtenPropertySet: Set<String>,
       configurationSchedulingLevel: Int?)
  {
    if !target.responds(to: selector) {
      assert(false,"Error \(target) does not respond to selector \(selector)")
    }
    
    self.target = target
    self.targetAction = selector
    self.keypathSet = keypathSet
    self.type = Swift.type(of: target)
    self.name = name
    self.unionReadKeypathSet = []
    self.writtenPropertySet = writtenPropertySet
    self.schedulingLevel = schedulingLevel
    self.configurationSchedulingLevel = configurationSchedulingLevel
    super.init()
    print("KeySetObserver: target \(name) type \(self.type) created with \(keypathSet)")
  }
  
  func insertValue(_ dataValue: String)
  {
    keypathSet.insert(dataValue)
    forcedDirty = TriggerState.updated(description: "\(dataValue) Inserted")
  }
  
  func removeValue(_ dataValue: String)
  {
    keypathSet.remove(dataValue)
    forcedDirty = TriggerState.updated(description: "\(dataValue) Removed")
  }
  
  // Return true is the delegate is nil => should discard this KeySetObserver
  func isValid() -> Bool
  {
    return self.target != nil
  }
  
  // return true is target matches, and if selector matches. Nil matches all selectors
  func matchesTarget(_ target: NSObject, selector: Selector? = nil) -> Bool
  {
    if target == self.target {
      if let selector = selector {
        return selector == self.targetAction
      } else {
        return true
      }
    }
    return false
  }
  
  func getReadKeypathSet() -> Set<String>
  {
    return keypathSet
  }
  
  fileprivate func updateDirtyStatus(_ dataDict: [String:KeypathObserver]) ->  (isDirty:Bool, description: String) {
    var desc: String = ""
    var isDirty = false
    
    for keypath in keypathSet
    {
      var currentChangeCount = -1
      if let dataValue = dataDict[keypath]
      {
        currentChangeCount = dataValue.updateCounter
      }
      if let previousVal = updateCounter[keypath] {
        if previousVal != currentChangeCount {
          desc = keypath
          isDirty = true
        }
      }
      updateCounter[keypath] = currentChangeCount
    }
    
    if forcedDirty.isDirty() {
      desc = forcedDirty.description
      forcedDirty = .normal
      isDirty = true
    }
    
    if isDirty {
      return (isDirty:true, description: desc)
    }
    
    if keypathSet.isEmpty {
      return (isDirty:true, description: "Trigger at each cycle (empty keypath set)")
    }
    
    return (isDirty:false, description: "Not Dirty")
  }
  
  fileprivate func readNodeSet(_ dataDict: [String:KeypathObserver]) ->  Set<RW_Action> {
    var result: Set<RW_Action> = []
    for keypath in keypathSet
    {
      if let keypathObserver = dataDict[keypath]
      {
        let nodes = keypathObserver.collectNodeSet()
        result.formUnion(nodes)
      }
    }
    return result
  }
  
  
  func triggerIfDirty(_ dataUsage: DataUsage?, dataDict: [String:KeypathObserver])
  {
    // Let check this if target has been released since last removal.
    guard let target = target else {
      print("Warning: KeySetObserver \(name). Attempt to perform refresh with nil target")
      return
    }
    
    let checkDirty = self.updateDirtyStatus(dataDict)
    if  !checkDirty.isDirty {
      return
    }
    
    print("Refresh \(self.name) because \(checkDirty.description)")
    
    // Normally performAction() should only read from the current dataset.
    
    // clearContext() clears the read and write actions, not the dirty flag
    // which is needed by other keySetObservers
    dataUsage?.clearContext(target)
    let nodeSet = self.readNodeSet(dataDict)
    
    
    target.perform(self.targetAction, with: nil)
    
    // Check consistency
    if let dataUsage = dataUsage {
      let readKeypathSet  = dataUsage.getReadKeypathObserverSet(target)
      
      for item in readKeypathSet {
        print("KeySetObserver: \(name) : Action Read: Node \(item.propertyDesc)")
      }
      
      let commonPropertySet = commonProperties(actionSet1: readKeypathSet, actionSet2: nodeSet)
      unionReadKeypathSet.formUnion(commonPropertySet)
      let writeKeypathSet = dataUsage.getWriteKeypathObserverSet(target)
      let result = KeySetObserver.compareArrays(
        readAction: readKeypathSet, configuredReadAction: nodeSet,
        writeAction: writeKeypathSet, configuredWriteProperties: writtenPropertySet,
        name: name)
      switch result {
      case .error_WriteDataSetNotEmpty(let delta):
        print("Warning: \(name) performs a write of \(delta) which is not part of the registered writtenProperty KeySetObserver. Consider manually adding these writtenProperty to the registered \(name) KeySetObserver")
      case .warning_ReadDataSetContainsMoreDataThanKeySetObserver(let delta):
        print("Warning: \(name) performs a read of \(delta) which is not part of the registered KeySetObserver. Consider manually adding this keypath to the registered \(name) KeySetObserver")
      default:
        break
      }
    }
  }
  
  func commonProperties(actionSet1:Set<RW_Action>, actionSet2:Set<RW_Action>) -> Set<String>
  {
    var propertySet : [String] = []
    for action in actionSet1 {
      let commonActions = actionSet2
        .filter({ action.isEquivalentTo($0) })
        .map({$0.propertyDesc})
      propertySet.append(contentsOf: commonActions)
    }
    return Set(propertySet)
  }
  
  
  func displayUsage(_ dataDict: [String:KeypathObserver]) -> DataSetComparisonResult<String>
  {
    var configuredProperties: Set<String> = []
    for keypath in keypathSet
    {
      if let dataValue = dataDict[keypath] {
        configuredProperties.formUnion(dataValue.propertyDescriptionSet)
      }
    }
    
    if unionReadKeypathSet == configuredProperties {
      print("Data Usage: Info: \(name) matches exactly its KeySetObserver")
      return DataSetComparisonResult.identical
    }
    
    if unionReadKeypathSet.isSubset(of: configuredProperties) {
      let delta = configuredProperties.subtracting(unionReadKeypathSet)
      print("Data Usage: Info: Read of \(name) does not perform read of \(delta) which is part of the registered KeySetObserver. This is normal if these values are not read at each refresh cycle")
      return DataSetComparisonResult.info_ReadDataSetIsContainedIntoKeySetObserver(delta)
    }
    
    let delta = unionReadKeypathSet.subtracting(configuredProperties)
    print("Data Usage: Warning: Read of \(name) performs a read of \(delta) which is not part of the registered KeySetObserver. Consider manually adding this keypath to the registered \(name) KeySetObserver")
    return DataSetComparisonResult.warning_ReadDataSetContainsMoreDataThanKeySetObserver(delta)
  }
  
  
  static func compareArrays(readAction:Set<RW_Action>, configuredReadAction:Set<RW_Action>,
                            writeAction:Set<RW_Action>, configuredWriteProperties:Set<String>,
                            name: String) -> DataSetComparisonResult<RW_Action>
  {
    let writeDelta = writeAction.filter { (action:RW_Action) -> Bool in
      return !configuredWriteProperties.contains(action.propertyDesc)
    }
    if !writeDelta.isEmpty {
      return DataSetComparisonResult.error_WriteDataSetNotEmpty(Set(writeDelta))
    }
    if readAction == configuredReadAction {
      return DataSetComparisonResult.identical
    }
    
    if readAction.isSubset(of: configuredReadAction) {
      let delta = configuredReadAction.subtracting(readAction)
      return DataSetComparisonResult.info_ReadDataSetIsContainedIntoKeySetObserver(delta)
    }
    let delta = readAction.subtracting(configuredReadAction)
    return DataSetComparisonResult.warning_ReadDataSetContainsMoreDataThanKeySetObserver(delta)
  }
  
}
