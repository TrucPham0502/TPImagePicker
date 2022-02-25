//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import UIKit
import Photos

class TPImagePickerCollectionViewCell: UICollectionViewCell {
    lazy var imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    fileprivate lazy var selectButton: UIButton = {
        let v = UIButton()
        v.addTarget(self, action: #selector(onTapImageCheck), for: .touchUpInside)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    fileprivate lazy var selectedIndex: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 15)
        v.textColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    fileprivate lazy var iconType : UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    fileprivate lazy var infoView: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        
        v.addSubview(videoLengthLabel)
        
        NSLayoutConstraint.activate([
            ///videoLengthLabel
            videoLengthLabel.rightAnchor.constraint(equalTo: v.rightAnchor, constant: -8),
            videoLengthLabel.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
       
        return v
    }()
    fileprivate lazy var videoLengthLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12, weight: .medium)
        v.textColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private weak var photoAsset: PhotoAsset?
    
    var onTapSelect = {}
    var onLongSelect = {}
    var onTapCheck = {}
    
    private var selectMode: SelectMode!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepareUI()
    }
    
    private func prepareUI() {
        contentView.clipsToBounds = true
        contentView.addSubview(imageView)
        contentView.addSubview(infoView)
        contentView.addSubview(selectButton)
        contentView.addSubview(selectedIndex)
        contentView.addSubview(iconType)
        
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapSelects(_:))))
        
        self.contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongSelects)))
        
        NSLayoutConstraint.activate([
            
            ///videoIcon
            iconType.heightAnchor.constraint(equalToConstant: 8),
            iconType.widthAnchor.constraint(equalToConstant: 17),
            iconType.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 8),
            iconType.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            
            ///  imageView Constraint
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            
            /// videoInfoView Constraint
            infoView.heightAnchor.constraint(equalToConstant: 24),
            infoView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            infoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            infoView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            
            /// selectButton Constraint
            selectButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            selectButton.heightAnchor.constraint(equalToConstant: 40),
            selectButton.widthAnchor.constraint(equalToConstant: 40),
            
            ///selectedIndex Constraint
            selectedIndex.centerXAnchor.constraint(equalTo: selectButton.centerXAnchor),
            selectedIndex.centerYAnchor.constraint(equalTo: selectButton.centerYAnchor),
            
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.imageView.image = nil
        self.infoView.isHidden = true
        self.iconType.isHidden = true
        
        self.photoAsset?.cancelAllRequest()
    }
    
    func loadView(photoAsset: PhotoAsset, selectMode: SelectMode, selectedIndex: Int?) {
        self.selectMode = selectMode
        
        if selectMode == .single {
            self.selectedIndex.isHidden = true
            self.selectButton.isHidden = true
        }
        
        self.photoAsset = photoAsset
        let cellSize = UIScreen.main.bounds.width / 3
        let size = CGSize(width: cellSize + 300, height: cellSize + 300)
        photoAsset.requestThumb(refresh: false, size: size) { progress, stop, error in
            print(progress)
        } _: {[weak self] image in
            guard let _self = self else { return }
            _self.imageView.image = image
        }
        
        photoAsset.thumbChanged = { [weak self, weak photoAsset] image in
            guard let strongSelf = self, let _ = photoAsset else { return }
            strongSelf.imageView.image = image
        }
        
        
        if photoAsset.mediaType == .video {
            prepareTypeIcon(image: Config.image.video_icon, time: photoAsset.asset?.duration.stringTime)
        }
        else {
            if photoAsset.mediaSubType == .photoLive {
                prepareTypeIcon(image: Config.image.live_photos)
            }
        }
       
        
        
        self.performSelectionAnimation(selectedIndex: selectedIndex)
    }
    @objc
    private func onTapSelects(_ sender: Any) {
        self.onTapSelect()
    }
    @objc
    private func  onLongSelects(_ sender: Any) {
        self.onLongSelect()
    }
    @objc
    private func  onTapImageCheck(_ sender: Any) {
        self.onTapCheck()
    }
    private func prepareTypeIcon(image : UIImage?, time : String? = nil){
        self.infoView.isHidden = time?.isEmpty ?? true
        self.iconType.isHidden = image == nil
        self.iconType.image = image
        self.videoLengthLabel.text = time
    }
    
    func performSelectionAnimation(selectedIndex: Int?) {
        if let selectedIndex = selectedIndex {
            if self.selectMode == .multiple {
                self.selectedIndex.isHidden = false
                self.selectedIndex.text = "\(selectedIndex + 1)"
                self.selectButton.setImage(Config.image.check_on, for: .normal)
            } else {
                self.selectedIndex.isHidden = true
                self.selectButton.setImage(Config.image.single_check_on, for: .normal)
            }
        } else {
            self.selectedIndex.isHidden = true
            self.selectButton.setImage(Config.image.check_off, for: .normal)
        }
    }
}
