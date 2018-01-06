//
//  NetworkMgr.swift
//  deezer
//
//  Created by Xavier Lasne on 02/12/2017.
//  Copyright  MIT License
//

import Foundation
import Alamofire
import AlamofireImage
import RxAlamofire
import RxSwift
import Quantwm

protocol DeezerAPI: class, DeezerTracksAPI, DeezerPlaylistAPI {
}

//TODO: Reachability
//TODO: Network conditioning tests

class NetworkMgr: ViewModel, DeezerAPI, GetMediator {

    //MARK: - Init & configuration

    let deezerPlaylist = DeezerPlaylist()
    let deezerTracks = DeezerTracks()

    // AlamofireImage Default configuration:
    // Image Cache 100 MB, 4 parallel downloads
    let imageDownloader = ImageDownloader(
        configuration: ImageDownloader.defaultURLSessionConfiguration(),
        downloadPrioritization: .lifo,
        maximumActiveDownloads: 4,
        imageCache: AutoPurgingImageCache()
    )

    func clearImageCache() {
        imageDownloader.imageCache?.removeAllImages()
    }

    init(mediator: Mediator) {
        super.init(mediator: mediator, owner: "NetworkMgr")
        qwMediator.updateActionAndRefresh(owner: "NetworkMgr") {
            registerObserver(
                registration: NetworkMgr.userIdUpdatedREG,
                target: self) { [weak self] in
                    self?.loadPlaylistsForUser()
            }


            registerObserver(
                registration: NetworkMgr.playlistSelectedREG,
                target: self) { [weak self] in
                    self?.loadSelectedPlaylistTracks()
            }
        }
    }


    static let userIdUpdatedREG: QWRegistration = QWRegistration(
        hardWithReadMap: QWModel.root.userId_Read,
        name: "NetworkMgr.userIdUpdated",
        schedulingPriority: -1)

    func loadPlaylistsForUser() {
        getRxPlaylist(userId: dataModel.userId)
    }


    //MARK: - GET Request: Set of tracks of selected playlist
    // Triggered by the selection of a playlist

    static let playlistSelectedREG: QWRegistration = QWRegistration(
        smartWithReadMap: QWModel.root.selectedPlaylistId_Read,
        name: "NetworkMgr.loadSelectedPlaylistTracks")

    @objc func loadSelectedPlaylistTracks() {
        if let playlistId = dataModel.selectedPlaylistId {
            self.getRxTrack(playlistId: playlistId)
        }
    }

}

extension NetworkMgr: DeezerPlaylistAPI {
    func getRxPlaylist(userId: UserID) {
        clearImageCache()
        deezerPlaylist.getRxPlaylist(userId: userId)
    }

    func subscribeToPlaylist(disposeBag: DisposeBag, completionHandler: @escaping (PlaylistChunk) -> ()) {
        deezerPlaylist.subscribeToPlaylist(disposeBag: disposeBag,
                                           completionHandler: completionHandler)
    }
}

extension NetworkMgr: DeezerTracksAPI {
    func getRxTrack(playlistId: PlaylistID) {
        deezerTracks.getRxTrack(playlistId: playlistId)
    }

    func subscribeToTrack(disposeBag: DisposeBag, completionHandler: @escaping (TrackChunk) -> ()) {
        deezerTracks.subscribeToTrack(disposeBag: disposeBag, completionHandler: completionHandler)
    }
}
