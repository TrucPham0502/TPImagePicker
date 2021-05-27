//
//  ImagePickerController.swift
//  BizWork
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2020 Quan Pham (VN). All rights reserved.
//

import UIKit
import Photos

struct TPContexMenu {
    let title : String
    let image : UIImage?
    let action : (UIAction) -> Void
}

enum SelectMode {
    case multiple
    case single
}

protocol TPImagePickerViewControllerDelegate: class {
    func fmPhotoPickerController(_ picker: TPImagePickerViewController, didFinishPickingPhotoWith photos: [UIImage])
}
class TPImagePickerViewController : UIViewController {
    private var lastY: CGFloat = 0
    private var minHeight: CGFloat = 320
    private var lastContentOffset: CGPoint = .zero
    private var tolerance: CGFloat = 0.0000001
    private var parentView : UIView?
    private var parentController : UIViewController?
    private var additionIndex : Int {
        return 1
    }
    var mediaType : [MediaType] = [.image, .video, .unsupported]
    var availableHeight: CGFloat {
        return parentController?.view.frame.height ?? 0
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    func invalidate() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    private let headerHeight : CGFloat = 80
    private weak var imageCollectionView: UICollectionView!
    private weak var numberOfSelectedPhoto: UILabel!
    private weak var doneButton: UIButton!
    private weak var cancelButton: UIButton!
    private weak var albumTitle: UILabel!
    private lazy var headerView : UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.fromGradientWithDirection(.topToBottom, frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: headerHeight), colors: [UIColor(red: 0, green: 0, blue: 0, alpha: 0.8),UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)])
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var imageAlbum : UIButton = {
        let v = UIButton()
        v.setImage(Config.image.ic_down_white, for: .normal)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var collectionViewInset : CGFloat {
        if headerView.layer.opacity == 0
        {
            return 0
        }
        if UIDevice.current.hasNotch
        {
            return headerHeight - 40
        }
        return headerHeight - 20
    }
    
    private weak var delegate: TPImagePickerViewControllerDelegate? = nil
    
    private var presentedPhotoIndex: Int?
    
    private var dataSource: PhotosDataSource!
    private var selectedGroup: GroupAsset?{
        didSet{
            self.albumTitle.text = selectedGroup?.groupName
        }
    }
    
    var contextMenus : [TPContexMenu] = []
    var numberOfColumns : CGFloat = 3
    var selectMode : SelectMode = .multiple
    var maxSelect = 5
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.traitCollection.forceTouchCapability == .available {
            let interaction = UIContextMenuInteraction(delegate: self)
            imageCollectionView.addInteraction(interaction)
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.dataSource == nil {
            self.requestAndFetchAssets()
        }
    }
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        initializeViews()
        setupView()
    }
    private func setupView() {
        self.imageCollectionView.register(TPImagePickerCollectionViewCell.self, forCellWithReuseIdentifier: TPImagePickerCollectionViewCell.reuseIdentifier)
        self.imageCollectionView.register(PhotoPickerImageCameraCell.self, forCellWithReuseIdentifier: PhotoPickerImageCameraCell.reuseIdentifier)
        self.imageCollectionView.dataSource = self
        self.imageCollectionView.delegate = self
        self.doneButton.isHidden = true
        self.cancelButton.setImage(Config.image.ic_Back_White, for: .normal)
    }
    
    @objc
    private func onTapCancel(_ sender: Any) {
        if self.parentController != nil{
            setPosition(availableHeight - minHeight, animated: true)
            return
        }
        self.dismiss(animated: true)
    }
    
    @objc
    private func onTapDone(_ sender: Any) {
        processDetermination()
    }
    @objc
    private func onTapAlbum(_ sender: Any) {
        let a = TPImagePickerGroupViewController(imagePickerController: self, mediaType: mediaType) { (group) in
            self.selectedGroup = group
            self.fetchPhotos()
        }
        PopoverViewController.popoverViewController(a, fromView: albumTitle)
    }
    
    // MARK: - Logic
    private
    func requestAndFetchAssets() {
        if Helper.canAccessPhotoLib() {
            if let group = Helper.fetchGroups().first
            {
                self.selectedGroup = GroupAsset(collection:  group, mediaType: mediaType)
            }
            self.fetchPhotos()
            PHPhotoLibrary.shared().register(self)
        } else {
            let okAction = UIAlertAction(
                title: Config.language.permission_button_ok,
                style: .default) { (_) in
                Helper.requestAuthorizationForPhotoAccess(authorized: self.fetchPhotos, rejected: Helper.openIphoneSetting)
            }
            
            let cancelAction = UIAlertAction(
                title: Config.language.permission_button_cancel,
                style: .cancel,
                handler: nil)
            
            Helper.showDialog(
                in: self,
                okAction: okAction,
                cancelAction: cancelAction,
                title: Config.language.permission_dialog_title,
                message: Config.language.permission_dialog_message
            )
        }
    }
    
    private func fetchPhotos() {
        let photoAssets = Helper.getAssets(allowMediaTypes: mediaType, group: self.selectedGroup)
        let fmPhotoAssets = photoAssets.map { PhotoAsset(asset: $0) }
        self.dataSource = PhotosDataSource(photoAssets: fmPhotoAssets)
        self.imageCollectionView.reloadData()
    }
    
    
    
    private func updateButtonDone() {
        if self.dataSource.numberOfSelectedPhoto() > 0 {
            self.doneButton.isHidden = false
            self.doneButton.setTitle(String(format:Config.language.send_Photo,self.dataSource.numberOfSelectedPhoto()), for: .normal)
        } else {
            self.doneButton.isHidden = true
        }
    }
    
    private func processDetermination() {
        var dict = [Int:UIImage]()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let multiTask = DispatchGroup()
            for (index, element) in self.dataSource.getSelectedPhotos().enumerated() {
                multiTask.enter()
                element.requestFullSizePhoto(){
                    guard let image = $0 else { return }
                    dict[index] = image
                    multiTask.leave()
                }
            }
            multiTask.wait()
            
            let result = dict.sorted(by: { $0.key < $1.key }).map { $0.value }
            DispatchQueue.main.async {
                
                self.dismiss(animated: true, completion: {
                    self.delegate?.fmPhotoPickerController(self, didFinishPickingPhotoWith: result)
                })
            }
        }
    }
    
    fileprivate func createPreviewImage(_ index : Int) -> ImageCarouselViewController{
        let imageCarousel = ImageCarouselViewController.create(
            imageDataSource: SimpleImageDatasource(
                imageItems: self.dataSource?.photoAssets.map {
                    ImageItem.asset($0, placeholder: $0.editedThumb)
                } ?? []),
            options: [.delegate(self), .theme(.dark)],
            initialIndex: index)
        return imageCarousel
    }
}
extension TPImagePickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let total = self.dataSource?.numberOfPhotos {
            return total + additionIndex
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0
        {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoPickerImageCameraCell.reuseIdentifier, for: indexPath) as? PhotoPickerImageCameraCell {
                cell.onTapSelect = {[unowned self, unowned cell] in
                    let vc = CameraViewController()
                    vc.delegate = self
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
                }
                return cell
            }
            return UICollectionViewCell()
        }
        else{
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TPImagePickerCollectionViewCell.reuseIdentifier, for: indexPath) as? TPImagePickerCollectionViewCell,
                  let photoAsset = self.dataSource.photo(atIndex: indexPath.item - additionIndex) else {
                return UICollectionViewCell()
            }
            
            cell.loadView(photoAsset: photoAsset,
                          selectMode: self.selectMode,
                          selectedIndex: self.dataSource.selectedIndexOfPhoto(atIndex: indexPath.item - additionIndex))
            cell.onTapCheck = { [weak self, weak cell] in
                guard  let _self = self, let _cell = cell else {
                    return
                }
                if let selectedIndex = _self.dataSource.selectedIndexOfPhoto(atIndex: indexPath.item - _self.additionIndex) {
                    _self.dataSource.unsetSeclectedForPhoto(atIndex: indexPath.item - _self.additionIndex)
                    _cell.performSelectionAnimation(selectedIndex: nil)
                    _self.reloadAffectedCellByChangingSelection(changedIndex: selectedIndex)
                } else {
                    _self.tryToAddPhotoToSelectedList(photoIndex: indexPath.item - _self.additionIndex)
                }
                _self.updateButtonDone()
                
            }
            cell.onTapSelect = {[weak self] in
                guard  let _self = self else {
                    return
                }
                _self.present(_self.createPreviewImage(indexPath.item - _self.additionIndex), animated: false, completion: nil)
            }
            return cell
        }
        
    }
    
    private func reloadAffectedCellByChangingSelection(changedIndex: Int) {
        let affectedList = self.dataSource.affectedSelectedIndexs(changedIndex: changedIndex)
        let indexPaths = affectedList.map { return IndexPath(row: $0 + additionIndex, section: 0) }
        self.imageCollectionView.reloadItems(at: indexPaths)
    }
    
    private func tryToAddPhotoToSelectedList(photoIndex index: Int) {
        if self.selectMode == .multiple {
            guard let fmMediaType = self.dataSource.mediaTypeForPhoto(atIndex: index) else { return }
            
            var canBeAdded = true
            
            switch fmMediaType {
            case .image:
                if self.dataSource.countSelectedPhoto(byType: .image) >= self.maxSelect {
                    canBeAdded = false
                }
            case .video:
                if self.dataSource.countSelectedPhoto(byType: .video) >= self.maxSelect {
                    canBeAdded = false
                    
                }
            case .unsupported:
                break
            }
            
            if canBeAdded {
                self.dataSource.setSeletedForPhoto(atIndex: index)
                self.imageCollectionView.reloadItems(at: [IndexPath(row: index + additionIndex, section: 0)])
                self.updateButtonDone()
            }
        } else {  // single selection mode
            var indexPaths = [IndexPath]()
            self.dataSource.getSelectedPhotos().forEach { photo in
                guard let photoIndex = self.dataSource.index(ofPhoto: photo) else { return }
                indexPaths.append(IndexPath(row: photoIndex + additionIndex, section: 0))
                self.dataSource.unsetSeclectedForPhoto(atIndex: photoIndex)
            }
            
            self.dataSource.setSeletedForPhoto(atIndex: index)
            indexPaths.append(IndexPath(row: index + additionIndex, section: 0))
            self.imageCollectionView.reloadItems(at: indexPaths)
            self.updateButtonDone()
        }
    }
}

// MARK: - UICollectionViewDelegate
extension TPImagePickerViewController: UICollectionViewDelegate {
    func makeContextMenu() -> UIMenu {
        let menu = self.contextMenus.map{
            UIAction(title: $0.title, image: $0.image, handler: $0.action)
        }
        return UIMenu(title: Config.language.context_menu_title, children: menu)
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: "\(indexPath.item)" as NSCopying, previewProvider: {
            if indexPath.item > 0 {
                let vc = self.createPreviewImage(indexPath.item - self.additionIndex)
                return vc
            }
            return nil
        }, actionProvider: { suggestedActions in
            return self.makeContextMenu()
        })
    }
    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
//        guard
//            let identifier = configuration.identifier as? String,
//            let index = Int(identifier)
//        else {
//            return
//        }
//        let cell = imageCollectionView.cellForItem(at: IndexPath(row: index, section: 0))
//        animator.addAnimations {
//            self.show(self.createPreviewImage(index - self.additionIndex), sender: cell)
//        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension TPImagePickerViewController: UIViewControllerTransitioningDelegate {
    
}

private extension TPImagePickerViewController {
    func initializeViews() {
        self.view.backgroundColor = .black
        
        let layout = TPImagePickerCollectionViewLayout(numberOfColumns: self.numberOfColumns)
        layout.sectionInset = UIEdgeInsets(top: collectionViewInset, left: 0, bottom: 75, right: 0)
        let imageCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.imageCollectionView = imageCollectionView
        imageCollectionView.backgroundColor = .clear
        
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageCollectionView)
        NSLayoutConstraint.activate([
            imageCollectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            imageCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            imageCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
        
        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight)
        ])
        
        
        let menuContainer = UIView()
        
        menuContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(menuContainer)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                menuContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                menuContainer.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            ])
        }
        NSLayoutConstraint.activate([
            menuContainer.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            menuContainer.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            menuContainer.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            menuContainer.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let cancelButton = UIButton()
        self.cancelButton = cancelButton
        cancelButton.addTarget(self, action: #selector(onTapCancel(_:)), for: .touchUpInside)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        menuContainer.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.leftAnchor.constraint(equalTo: menuContainer.leftAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: menuContainer.centerYAnchor),
        ])
        
        
        
        let albumTitle = UILabel()
        self.albumTitle = albumTitle
        albumTitle.text = "Album"
        albumTitle.textColor = .white
        albumTitle.translatesAutoresizingMaskIntoConstraints = false
        menuContainer.addSubview(self.albumTitle)
        albumTitle.isUserInteractionEnabled = true
        albumTitle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapAlbum(_:))))
        NSLayoutConstraint.activate([
            albumTitle.centerXAnchor.constraint(equalTo: menuContainer.centerXAnchor),
            albumTitle.centerYAnchor.constraint(equalTo: menuContainer.centerYAnchor)
        ])
        
        self.view.addSubview(imageAlbum)
        NSLayoutConstraint.activate([
            imageAlbum.leadingAnchor.constraint(equalTo: albumTitle.trailingAnchor, constant: 15),
            imageAlbum.centerYAnchor.constraint(equalTo: menuContainer.centerYAnchor)
        ])
        
        
        let doneButton = UIButton(type: .system)
        self.doneButton = doneButton
        doneButton.addTarget(self, action: #selector(onTapDone(_:)), for: .touchUpInside)
        
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(doneButton)
        NSLayoutConstraint.activate([
            doneButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            doneButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -25),
            doneButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
        ])
        
    }
    
}
extension TPImagePickerViewController : PHPhotoLibraryChangeObserver{
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let group = self.selectedGroup else { return }
        if let fetchResult = group.fetchResult, let changeDetails = changeInstance.changeDetails(for: fetchResult) {
            self.selectedGroup?.updateGroup(fetchResult: changeDetails.fetchResultAfterChanges)
            let removedAssets = changeDetails.removedObjects.map{ PhotoAsset(asset: $0) }
            if removedAssets.count > 0 {
                DispatchQueue.main.async {
                    self.fetchPhotos()
                }
                return
            }
            
            let insertedAssets = changeDetails.insertedObjects.map{ PhotoAsset(asset: $0)}
            if insertedAssets.count > 0  {
                DispatchQueue.main.async {
                    self.fetchPhotos()
                }
                return
            }
        }
    }
}
extension TPImagePickerViewController : CameraViewControllerDelegate
{
    func camera(_ view: CameraViewController, capture image: UIImage) {
        self.dismiss(animated: true, completion: {
            self.delegate?.fmPhotoPickerController(self, didFinishPickingPhotoWith: [image])
        })
    }
}

extension TPImagePickerViewController {
    
    func addTo(_ vc : UIViewController, to view : UIView, completion: (()->Void)? = nil)
    {
        parentView = view
        parentController = vc
        headerView.layer.opacity = 0
        imageAlbum.layer.opacity = 0
        vc.addChild(self)
        view.addSubview(self.view)
        self.didMove(toParent: vc)
        let f = CGRect(x: vc.view.frame.minX, y: vc.view.frame.minY, width: vc.view.frame.width, height: minHeight)
        view.frame = f.offsetBy(dx: 0, dy: f.height)
        self.view.frame = view.bounds
        UIView.animate(withDuration: 0.3, animations: {
            view.frame = f
        }) { (_) in
            completion?()
        }
        setPosition(availableHeight - minHeight, animated: false)
        startTracking()
    }
    public func setPosition(_ minYPosition: CGFloat, animated: Bool){
        self.endTranslate(to: minYPosition, animated: animated)
    }
    
    private func startTracking(){
        imageCollectionView.panGestureRecognizer.addTarget(self, action: #selector(handleScrollPan(_:)))
        let pan = UIPanGestureRecognizer(target: self, action:  #selector(handleViewPan(_:)))
        headerView.addGestureRecognizer(pan)
        let navBarPan = UIPanGestureRecognizer(target: self, action:  #selector(handleViewPan(_:)))
        imageCollectionView.gestureRecognizers?.forEach({ (recognizer) in
            pan.require(toFail: recognizer)
            navBarPan.require(toFail: recognizer)
        })
    }
    @objc private func handleViewPan(_ recognizer: UIPanGestureRecognizer){
        handlePan(recognizer)
    }
    
    @objc private func handleScrollPan(_ recognizer: UIPanGestureRecognizer) {
        guard let scrollView = recognizer.view as? UIScrollView else {return}
        handlePan(recognizer, scrollView: scrollView)
    }
    
    private func handlePan(_ recognizer: UIPanGestureRecognizer, scrollView: UIScrollView? = nil){
        let dy = recognizer.translation(in: recognizer.view).y
        let vel = recognizer.velocity(in: recognizer.view)
        
        switch recognizer.state {
        case .began:
            lastY = 0
            if let scroll = scrollView{
                lastContentOffset.y = scroll.contentOffset.y + dy
            }
        case .changed:
            translate(with: vel, dy: dy, scrollView: scrollView)
        case .ended,
             .cancelled,
             .failed:
            let minY = parentView!.frame.minY
            if let scroll = scrollView{
                switch dragDirection(vel) {
                case .up where minY > tolerance:
                    scroll.setContentOffset(lastContentOffset, animated: false)
                    self.finishDragging(with: vel, position: minY)
                case .down where scroll.contentOffset.y <= 0:
                    self.finishDragging(with: vel, position: minY)
                default:
                    break
                }
            }
        default: break
        }
        
    }
    
    private func finishDragging(with velocity: CGPoint, position: CGFloat){
        let y = filteredPositions(velocity, currentPosition: position)
        endTranslate(to: y, animated: true)
    }
    
    private func filteredPositions(_ velocity: CGPoint, currentPosition: CGFloat) -> CGFloat{
        if velocity.y < 100 { /// dragging up
            return 0
        }else if velocity.y > 100 { /// dragging down
            return availableHeight - minHeight
        }else{
            return 0
        }
    }
    
    private func endTranslate(to position: CGFloat, animated: Bool = false){
        let oldFrame = parentView!.frame
        let height = availableHeight - position
        let f = CGRect(x: 0, y: position, width: oldFrame.width, height: height)
        if animated{
            animate(animations: {
                self.parentView!.frame = f
                self.view.frame.size = f.size
                let opacity = Float((self.availableHeight - self.minHeight - position) / (self.availableHeight - self.minHeight))
                self.imageAlbum.layer.opacity = opacity
                self.headerView.layer.opacity = opacity
                if let flow = self.imageCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
                {
                    flow.sectionInset = UIEdgeInsets(top: self.collectionViewInset, left: 0, bottom: 75, right: 0)
                }
                self.parentController!.view.layoutIfNeeded()
            }, completion: { finished in
            })
        }else{
            self.parentView!.frame = f
        }
    }
    
    func translate(with velocity: CGPoint, dy: CGFloat, scrollView: UIScrollView? = nil){
        if let scroll = scrollView{
            switch dragDirection(velocity) {
            case .up where (parentView!.frame.minY > tolerance):
                applyTranslation(dy: dy - lastY)
                scroll.contentOffset.y = lastContentOffset.y
            case .down where scroll.contentOffset.y <= 0:
                applyTranslation(dy: dy - lastY)
                scroll.contentOffset.y = 0
                lastContentOffset = .zero
            default:
                break
            }
        }
        lastY = dy
    }
    
    private func dragDirection(_ velocity: CGPoint) -> DraggingState{
        if velocity.y < 0 {
            return .up
        }else if velocity.y > 0{
            return .down
        }else{
            return .idle
        }
    }
    private func applyTranslation(dy: CGFloat){
        let oldFrame = parentView!.frame
        let newY = oldFrame.minY + dy
        
        let height = availableHeight - newY
        let f = CGRect(x: 0, y: newY, width: oldFrame.width, height: height)
        parentView?.frame = f
        self.view.frame.size = f.size
        self.headerView.layer.opacity = Float((self.availableHeight - self.minHeight - newY) / (self.availableHeight - self.minHeight))
        
        
    }
    private func animate(animations: @escaping () -> Void, completion: ((Bool) -> Void)?){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [.curveEaseInOut, .allowUserInteraction], animations: animations, completion: completion)
    }
    
    private enum DraggingState{
        case up, down, idle
    }
    
}
extension TPImagePickerViewController : ImageCarouselViewControllerDelegate {
    func imageViewer(_ view: ImageCarouselViewController, sourceView index: Int) -> UIImageView? {
        return (imageCollectionView.cellForItem(at: .init(row: index + additionIndex, section: 0)) as? TPImagePickerCollectionViewCell)?.imageView
    }
    
    func imageViewer(_ controller: ImageCarouselViewController, viewer: ImageViewerController, viewDidAppear index: Int) {
        let indexPath = IndexPath(item: index + additionIndex, section: 0)
        if let max = imageCollectionView.indexPathsForVisibleItems.max(by: { (pre, idx) -> Bool in
            pre.item < idx.item
        }), let min = imageCollectionView.indexPathsForVisibleItems.min(by: { (pre, idx) -> Bool in
            pre.item < idx.item
        }){
            if indexPath.item + Int(numberOfColumns) > max.item  || indexPath.item - Int(numberOfColumns) < min.item {
                imageCollectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
            }
        }
        
    }
    
    func imageViewer(_ controller: ImageCarouselViewController, viewer: ImageViewerController, viewDidLoad index: Int) {
        
    }
}
extension TPImagePickerViewController : UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    
    
}
