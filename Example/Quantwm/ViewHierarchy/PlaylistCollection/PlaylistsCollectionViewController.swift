//
//  PlaylistsCollectionViewController.swift
//  deezer
//
//  Created by Xavier on 02/12/2017.
//  Copyright © 2017 XL Software Solutions. => MIT License
//

import UIKit
import AlamofireImage
import Quantwm

final class PlaylistsCollectionViewController: UICollectionViewController, MyModel {

    @IBOutlet weak var titleItem: UINavigationItem!
    
    var viewModel: PlaylistsCollectionViewModel?

    override  func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let model = QWModel.root.playlistsCollection
        let viewModel = PlaylistsCollectionViewModel(dataModel: dataModel, owner: "PlaylistsCollectionViewController", playlistCollectionModel: model)
        navigationController?.setToolbarHidden(true, animated: true)
        self.viewModel = viewModel
        viewModel.updateActionAndRefresh {
            viewModel.registerObserver(
                target: self,
                registrationDesc: playlistUpdatedREG(viewModel: viewModel))
        }
        viewModel.updateActionAndRefresh {
            viewModel.registerObserver(
                target: self,
                registrationDesc: userIdREG(viewModel: viewModel))
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: true)
        super.viewDidDisappear(animated)
        viewModel?.unregisterDataSet(target: self)
        viewModel = nil
    }

    // Registration to Playlist Collection update

    //MARK: - REGISTRATION

    func playlistUpdatedREG(viewModel: PlaylistsCollectionViewModel) -> QWRegistration {
        return QWRegistration(
            selector: #selector(PlaylistsCollectionViewController.playlistsCollectionUpdated),
            qwMap: viewModel.mapForPlaylistCollectionDataSource,
            name: "PlaylistsCollectionViewController.playlistsCollectionUpdated")
    }

    @objc func playlistsCollectionUpdated() {
        collectionView?.reloadData()
    }

    func userIdREG(viewModel: PlaylistsCollectionViewModel) -> QWRegistration {
        return QWRegistration(
        selector: #selector(PlaylistsCollectionViewController.titleUpdated),
        qwMap: viewModel.mapForTitle,
        name: "PlaylistsCollectionViewController.titleUpdated")
    }

    @objc func titleUpdated() {
        if let title = viewModel?.getTitle() {
            titleItem.title = title
        } else {
            titleItem.title = ""
        }
    }

    //MARK: - ACTIONS

    @IBAction func previousUserAction(_ sender: Any) {
        viewModel?.selectPreviousUser()
    }

    @IBAction func nextUserAction(_ sender: Any) {
        viewModel?.selectNextUser()
    }

}

// MARK: - UICollectionViewDataSource
// Performed under PlaylistsCollectionViewModel.playlistCollectionDataSourceMap access
// PlaylistsCollectionViewModel.playlistCollectionDataSourceMap-> Trigger reloadData
// reloadData only trigger the refresh of the visible cells, no need to re-read all the cells
// Cover images are cached via AlamoFire

fileprivate let reuseIdentifier = "PlaylistCell"

extension PlaylistsCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return viewModel?.playlistCount() ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! PlaylistCell

        let coverInfo = viewModel?.playlistCoverInfoForIndexPath(indexPath: indexPath)
        cell.configureCell(coverInfo: coverInfo)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension PlaylistsCollectionViewController
{
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let vm = viewModel {
            // Only valid cells can be selected
            return vm.isPlaylistExistingFor(indexPath: indexPath)
        } else {
            return false
        }
    }

    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected \(indexPath)")
        // In Storyboard, Playlist Cell has a triggered segue linked to the
        // next controller, segue will present the next controller on selection
        if let _ = viewModel?.playlistIDForIndexPath(indexPath: indexPath) {
            viewModel?.selectPlaylist(indexPath: indexPath)
        } else {
                assert(false,"If we are here, then playlist is valid ... then what happened ?")
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

// Pure UI, not external dependencies

fileprivate let sectionInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
fileprivate let itemsPerRow: CGFloat = 3

extension PlaylistsCollectionViewController : UICollectionViewDelegateFlowLayout {

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flowLayout.invalidateLayout()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
