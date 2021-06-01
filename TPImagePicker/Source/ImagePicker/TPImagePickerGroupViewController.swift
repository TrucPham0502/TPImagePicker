//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import Photos
import UIKit

class TPImagePickerGroupViewController: UITableViewController {
    
    private var groupDataSource: GroupDataSource!
    
    var showsEmptyAlbums = true
    
    let mediaType : [MediaType]
    
    fileprivate var selectedGroup: GroupAsset?
    
    fileprivate var selectedGroupDidChangeBlock:((_ group: GroupAsset?)->())?
    
    override var preferredContentSize: CGSize {
        get {
            if let groups = self.groupDataSource {
                return CGSize(width: UIView.noIntrinsicMetric,
                              height: CGFloat(groups.numberOfGroup) * self.tableView.rowHeight)
            } else {
                return super.preferredContentSize
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    
    internal weak var imagePickerController: TPImagePickerViewController!
    
    init(imagePickerController: TPImagePickerViewController, mediaType : [MediaType],
         selectedGroupDidChangeBlock: @escaping (_ groupId: GroupAsset?) -> ()) {
        self.mediaType = mediaType
        self.imagePickerController = imagePickerController
        self.selectedGroupDidChangeBlock = selectedGroupDidChangeBlock
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchGroups()
        self.tableView.register(TPImagePickerGroupViewCell.self, forCellReuseIdentifier: TPImagePickerGroupViewCell.reuseIdentifier)
        self.tableView.rowHeight = TPImagePickerGroupViewCell.preferredHeight
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.white.withAlphaComponent(0)
        self.clearsSelectionOnViewWillAppear = false
    }
    
    private func fetchGroups(){
        let groupAsset = Helper.fetchGroups()
        let fmGroupAssets = groupAsset.map { GroupAsset(collection: $0, mediaType: mediaType) }
        self.groupDataSource = GroupDataSource(collectionAssets: fmGroupAssets)
        
        if self.groupDataSource.numberOfGroup > 0 {
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - UITableViewDelegate, UITableViewDataSource methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groupDataSource?.numberOfGroup ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TPImagePickerGroupViewCell.reuseIdentifier, for: indexPath) as? TPImagePickerGroupViewCell else {
            assertionFailure("Expect groups and cell")
            return UITableViewCell()
        }
        
        guard let assetGroup = self.groupDataSource.group(atIndex: indexPath.row) else {
            assertionFailure("Expect group")
            return UITableViewCell()
        }
        
        cell.configure(with: assetGroup, tag: indexPath.row + 1)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let groups = self.groupDataSource, groups.numberOfGroup > indexPath.row else {
            assertionFailure("Expect groups with count > \(indexPath.row)")
            return
        }
        
        self.selectedGroup =  self.groupDataSource.group(atIndex: indexPath.row)
        selectedGroupDidChangeBlock?(self.selectedGroup)
        PopoverViewController.dismissPopoverViewController()
    }
    
    // MARK: - DKImageGroupDataManagerObserver methods

    
    @objc func cancelButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
