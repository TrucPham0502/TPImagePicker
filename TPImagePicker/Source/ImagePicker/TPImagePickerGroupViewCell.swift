//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import Foundation
import UIKit
class TPImagePickerGroupViewCell: UITableViewCell {
    static let preferredHeight: CGFloat = 70
    private lazy var assetGroupSeparator : UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    fileprivate lazy var thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.backgroundColor = Config.color.onBackgroundDisable
        return thumbnailImageView
    }()

    lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var totalCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13, *) {
            label.textColor = UIColor.secondaryLabel
        } else {
            label.textColor = UIColor.gray
        }
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        prepareUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareUI()
    }


    func configure(with assetGroup: GroupAsset, tag: Int) {
        self.tag = tag
        groupNameLabel.text = assetGroup.groupName
        if assetGroup.totalCount == 0 {
            thumbnailImageView.image = UIImage()
        } else {
            assetGroup.fetchGroupThumbnail(size: CGSize(width:  TPImagePickerGroupViewCell.preferredHeight, height: TPImagePickerGroupViewCell.preferredHeight), progress: { pro, stop, error in
                print(pro)
            }, completeBlock: {[weak self] (image) in
                guard let _self = self else { return }
                if _self.tag == tag {
                    _self.thumbnailImageView.image = image
                }
            })
        }
        totalCountLabel.text = String(assetGroup.totalCount)
    }
    
    
    fileprivate func prepareUI(){
        self.contentView.addSubview(self.thumbnailImageView)
        self.contentView.addSubview(self.groupNameLabel)
        self.contentView.addSubview(self.totalCountLabel)
        self.contentView.addSubview(self.assetGroupSeparator)
        
        let imageViewY = CGFloat(10)
        let imageViewHeight = TPImagePickerGroupViewCell.preferredHeight - 2 * imageViewY
        NSLayoutConstraint.activate([
            ///thumbnailImageView
            thumbnailImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: imageViewY),
            thumbnailImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: imageViewY),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: imageViewHeight),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: imageViewHeight),
            thumbnailImageView.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor, constant: -imageViewY),
            
            
            ///groupNameLabel
            groupNameLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: -10),
            groupNameLabel.leadingAnchor.constraint(equalTo: self.thumbnailImageView.trailingAnchor, constant: 10),
            groupNameLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0),
            
            ///totalCountLabel
            totalCountLabel.topAnchor.constraint(equalTo: self.groupNameLabel.bottomAnchor, constant: 10),
            totalCountLabel.leadingAnchor.constraint(equalTo: self.groupNameLabel.leadingAnchor, constant: 0),
            totalCountLabel.trailingAnchor.constraint(equalTo: self.groupNameLabel.trailingAnchor, constant: 0),
            
        ])
    }
}
