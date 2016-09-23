//
//  DemoDocument.swift
//  MVVM
//
//  Created by Xavier Lasne on 08/04/16.
//  Copyright © 2016 XL Software Solutions
//


import Cocoa

class DemoDocument: NSDocument {

  var dataModel: DataModel

  var repositoryObserver: RepositoryObserver {
    return self.dataModel.repositoryObserver
  }

  override init() {
    self.dataModel = DataModel()
    super.init()
    self.dataModel.postInit(document: self)
    // Add your subclass-specific initialization here.
  }

  override class func autosavesInPlace() -> Bool {
    return true
  }

  override func makeWindowControllers() {
    // Returns the Storyboard that contains your DemoDocument window.
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController
    self.addWindowController(windowController)
  }

  override func data(ofType typeName: String) throws -> Data {
    return NSKeyedArchiver.archivedData(withRootObject: dataModel)
  }

  override func read(from data: Data, ofType typeName: String) throws {
    if let model = NSKeyedUnarchiver.unarchiveObject(with: data) as? DataModel {
      self.dataModel = model
    } else {
      self.dataModel = DataModel()
    }
    self.dataModel.postInit(document: self)
  }

  func windowDidDeminiaturize(_ notification: Notification)
  {
    self.dataModel.postInit(document: self)
  }

}

