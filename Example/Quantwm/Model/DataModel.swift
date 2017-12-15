//
//  DataModel.swift
//  deezer
//
//  Created by Xavier on 02/12/2017.
//  Copyright © 2017 XL Software Solutions. => MIT License
//

import UIKit
import Foundation
import RxSwift
import Quantwm

protocol MyModel {
    var dataModel: DataModel { get }
}

// Valid in the view hiearchy
extension MyModel {
    var dataModel: DataModel {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.dataModel!
    }
}

class DataModel : NSObject, QWRoot_S, QWMediatorOwner_S, QWNode_S  {
    
    static let debug_userID = 10
    
    unowned var networkMgr: DeezerAPI
    var coordinator: Coordinator = Coordinator()

    init(networkMgr: DeezerAPI) {
        
        self.networkMgr = networkMgr
        _userId = DataModel.debug_userID
        super.init()

        _playlistsCollection.updateUserId(userId: userId)

        qwMediator.registerRoot(
            associatedObject: self,
            rootDescription: DataModel.dataModelK)
        
        networkMgr.postInitialization(dataModel: self)
    }
    
    var disposeBag = DisposeBag()

    func applicationBecomeActive() {

        networkMgr.subscribeToPlaylist(disposeBag: disposeBag) {[weak self] (indexedPlaylist: PlaylistChunk) in
            print("Data Model handler Playlist index:\(indexedPlaylist.index) count:\(indexedPlaylist.playlists.count)")
            if let me = self {
                me.qwMediator.updateActionAndRefresh(owner: me) {
                    me.playlistsCollection.importChunck(chunk: indexedPlaylist)
                }
            }
        }

        networkMgr.subscribeToTrack(disposeBag: disposeBag) {[weak self] (indexedTrack: TrackChunk) in
            print("Data Model handler Tracks index:\(indexedTrack.index) count:\(indexedTrack.data.count)")
            if let me = self {
                me.qwMediator.updateActionAndRefresh(owner: me) {
                    me.trackCollection.importChunck(chunk: indexedTrack)
                }
            }
        }

        qwMediator.updateActionAndRefresh(owner: self) {
            coordinator.postInit(dataModel: self)
        }
    }

    func applicationBecomeInactive() {
        disposeBag = DisposeBag()
    }
    
    // The model is:
    //   DataModel
    //      |
    //      |-playlistsCollection:PlaylistsCollection - node      -> PlaylistCollectionViewController.playlistUpdatedREG
    //      |      |
    //      |      |-playlistArray:[PlaylistID] - prop            -> PlaylistCollectionViewController.playlistUpdatedREG
    //      |      |
    //      |      L- playlistDict:[PlaylistID:Playlist] - prop   -> PlaylistCollectionViewController.playlistUpdatedREG
    //      |
    //      |-trackCollection:TrackCollection - node
    //      |      |
    //      |      |-trackDict: [PlaylistID:Tracklist] - prop     -> TracklistTableViewController.tracklistREG
    //      |
    //      |-selectedPlaylistId:PlaylistID? - prop               -> NetworkMgr.playlistSelectedREG
    //                                                            -> TracklistTableViewController.tracklistREG
    
    

    // MARK: - Quantwm Properties and Nodes
    
    // sourcery: root
    static let dataModelK = QWRootProperty(sourceType: DataModel.self, description: "dataModel")

    // sourcery: property
    var _userId : UserID

    // sourcery: property
    var _selectedPlaylistId : PlaylistID?
    
    // sourcery: node
    var _playlistsCollection : PlaylistsCollection = PlaylistsCollection()

    // sourcery: node
    var _trackCollection : TrackCollection = TrackCollection()

    // MARK: - GETTER
    static let selectedPlaylistMap = QWModel.root.selectedPlaylistId.map +
        QWModel.root.playlistsCollection.playlistDict.map +
        QWModel.root.playlistsCollection.playlistArray.map

    var selectedPlaylist: Playlist? {
        if let playlistId = selectedPlaylistId {
            return playlistsCollection.playlist(playlistId: playlistId)
        }
        return nil
    }

    static let selectedTracklistMap = QWModel.root.selectedPlaylistId.map
        + QWModel.root.trackCollection.trackDict.all.map

    var selectedTracklist: Tracklist? {
        if let playlistId = selectedPlaylistId {
            return trackCollection.trackDict[playlistId]
        }
        return nil
    }

    // MARK: - UPDATE
    func synchronizeTracksFromPlaylistCollection() {
        let playlistIdArray = playlistsCollection.playlistArray
        trackCollection.updateTracks(playlistIdArray: playlistIdArray)
    }


    // sourcery:inline:DataModel.QuantwmDeclarationInline

    // MARK: - Sourcery

    // QWMediatorOwner Protocol
    let qwMediator = QWMediator()
    func getQWMediator() -> QWMediator
    {
      return qwMediator
    }

    // QWNode protocol
    func getQWCounter() -> QWCounter {
      return qwCounter
    }
    let qwCounter = QWCounter(name:"DataModel")

    // Quantwm Property Array generation
    func getQWPropertyArray() -> [QWProperty] {
        return DataModel.qwPropertyArrayK
    }
    static let qwPropertyArrayK:[QWProperty] = [
      userIdK,  // property
      selectedPlaylistIdK,  // property
      playlistsCollectionK,   // node
      trackCollectionK,   // node
    ]

    // Quantwm Property: userId
    static let userIdK = QWProperty(
        propertyKeypath: \DataModel.userId,
        description: "_userId")
    var userId : UserID {
      get {
        self.qwCounter.performedReadOnMainThread(DataModel.userIdK)
        return _userId
      }
      set {
        self.qwCounter.performedWriteOnMainThread(DataModel.userIdK)
        _userId = newValue
      }
    }
    // Quantwm Property: selectedPlaylistId
    static let selectedPlaylistIdK = QWProperty(
        propertyKeypath: \DataModel.selectedPlaylistId,
        description: "_selectedPlaylistId")
    var selectedPlaylistId : PlaylistID? {
      get {
        self.qwCounter.performedReadOnMainThread(DataModel.selectedPlaylistIdK)
        return _selectedPlaylistId
      }
      set {
        self.qwCounter.performedWriteOnMainThread(DataModel.selectedPlaylistIdK)
        _selectedPlaylistId = newValue
      }
    }
    // Quantwm Node:  playlistsCollection
    static let playlistsCollectionK = QWNodeProperty(
        keypath: \DataModel.playlistsCollection,
        description: "_playlistsCollection")
    var playlistsCollection : PlaylistsCollection {
      get {
        self.qwCounter.performedReadOnMainThread(DataModel.playlistsCollectionK)
        return _playlistsCollection
      }
      set {
        self.qwCounter.performedWriteOnMainThread(DataModel.playlistsCollectionK)
        _playlistsCollection = newValue
      }
    }
    // Quantwm Node:  trackCollection
    static let trackCollectionK = QWNodeProperty(
        keypath: \DataModel.trackCollection,
        description: "_trackCollection")
    var trackCollection : TrackCollection {
      get {
        self.qwCounter.performedReadOnMainThread(DataModel.trackCollectionK)
        return _trackCollection
      }
      set {
        self.qwCounter.performedWriteOnMainThread(DataModel.trackCollectionK)
        _trackCollection = newValue
      }
    }
    // sourcery:end
    
}
