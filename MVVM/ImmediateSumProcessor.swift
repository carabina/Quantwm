//
//  ImmediateSumProcessor.swift
//  MVVM
//
//  Created by Xavier Lasne on 09/04/16.
//  Copyright © 2016 XL Software Solutions
//

// Owned by Data Model
// Example of performing processing in background
// After background update, update data model on the main thread
//  and triggers UI refresh via Context Mgr


import Foundation
import QuantwmOSX

class ImmediateSumProcessor: NSObject
{

  weak var dataModel : DataModel?

  override init()
  {
    super.init()
  }

  deinit
  {
    self.dataModel?.repositoryObserver.displayUsage(owner: self)
  }

  func register()
  {
    let obs1 = KeypathDescription(root:DataModel.dataModelK, chain: [DataModel.number1K])
    let obs2 = KeypathDescription(root:DataModel.dataModelK, chain: [DataModel.number2K])
    self.dataModel?.repositoryObserver.registerObserver(
      target: self,
      selector: #selector(ImmediateSumProcessor.startProcessing),
      keypathDescriptionSet: Set([obs1,obs2]),
      name: "ImmediateSumProcessor",
      writtenPropertySet: Set([DataModel.invSumOfNumberK]))
  }

  @objc func startProcessing()
  {
    if let number1 = self.dataModel?.number1,
      let number2 = self.dataModel?.number2
    {
      self.dataModel?.invSumOfNumber = -(number1 + number2)
    }
  }
}
