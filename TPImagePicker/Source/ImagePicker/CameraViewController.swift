//
//  CameraViewController.swift
//  BizWork
//
//  Created by Truc Pham on 9/16/20.
//  Copyright © 2020 Quan Pham (VN). All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

@objc
protocol CameraViewControllerDelegate {
    func camera(_ view: CameraViewController, capture image: UIImage)
}

class CameraViewController: UIViewController {
    // MARK: - Constants
    weak var delegate : CameraViewControllerDelegate?
    var cameraOutputMode : CameraOutputMode = .stillImage
    let cameraManager = CameraManager()
    
    private lazy var headerView : UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var flashModeImageView : UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var outputImageView : UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var cameraTypeImageView : UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var qualityLabel : UILabel = {
        let v = UILabel()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var cameraView : UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var footerView : UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var cameraButton : UIButton = {
        let v = UIButton()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var locationButton : UIButton = {
        let v = UIButton()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var backButton : UIButton = {
        let v = UIButton()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    let darkBlue = UIColor(red: 4 / 255, green: 14 / 255, blue: 26 / 255, alpha: 1)
    let lightBlue = UIColor(red: 24 / 255, green: 125 / 255, blue: 251 / 255, alpha: 1)
    let redColor = UIColor(red: 229 / 255, green: 77 / 255, blue: 67 / 255, alpha: 1)
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.cameraView)
        
        self.view.addSubview(self.headerView)
        self.headerView.addSubview(self.backButton)
        self.headerView.addSubview(self.flashModeImageView)
        
        self.view.addSubview(self.footerView)
        self.footerView.addSubview(self.cameraButton)
        self.footerView.addSubview(self.cameraTypeImageView)
        prepareHeaderView()
        prepreaFlashImage()
        prepareFooterView()
        prepareChangeCamera()
        preareCameraView()
        prepareCameraButton()
        setupCameraManager()
        preparBackButton()
        
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                cameraManager.shouldUseLocationServices = true
                locationButton.isHidden = true
            default:
                cameraManager.shouldUseLocationServices = false
            }
        }
        
        let currentCameraState = cameraManager.currentCameraStatus()
        
        if currentCameraState == .notDetermined {
            askForCameraPermissions()
        } else if currentCameraState == .ready {
            addCameraToView()
        } else {
            dismiss(animated: true, completion: nil)
        }
        
        if cameraManager.hasFlash {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changeFlashMode))
            flashModeImageView.addGestureRecognizer(tapGesture)
            flashModeImageView.isHidden = false
        }
        
        outputImageView.image = UIImage(named: "check_on")
        let outputGesture = UITapGestureRecognizer(target: self, action: #selector(outputModeButtonTapped))
        outputImageView.addGestureRecognizer(outputGesture)
        
        let cameraTypeGesture = UITapGestureRecognizer(target: self, action: #selector(changeCameraDevice))
        cameraTypeImageView.addGestureRecognizer(cameraTypeGesture)
        
        qualityLabel.isUserInteractionEnabled = true
        let qualityGesture = UITapGestureRecognizer(target: self, action: #selector(changeCameraQuality))
        qualityLabel.addGestureRecognizer(qualityGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraManager.resumeCaptureSession()
        cameraManager.startQRCodeDetection { result in
            switch result {
            case .success(let value):
                print(value)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraManager.stopQRCodeDetection()
        cameraManager.stopCaptureSession()
    }
    
    // MARK: - ViewController
    fileprivate func setupCameraManager() {
        cameraManager.cameraOutputMode = self.cameraOutputMode
        cameraManager.shouldEnableExposure = true
        
        cameraManager.writeFilesToPhoneLibrary = false
        
        cameraManager.shouldFlipFrontCameraImage = false
        cameraManager.showAccessPermissionPopupAutomatically = false
    }
    
    
    fileprivate func addCameraToView() {
        cameraManager.addPreviewLayerToView(cameraView, newCameraOutputMode: self.cameraOutputMode)
        cameraManager.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (_) -> Void in }))
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - @Objc
    
    @objc func onTapBack(_ sender : UIButton)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func changeFlashMode(_ sender: UIButton) {
        switch cameraManager.changeFlashMode() {
        case .off:
            flashModeImageView.image = Config.image.ic_camera_flash_off
        case .on:
            flashModeImageView.image = Config.image.ic_camera_flash_on_white
        case .auto:
            flashModeImageView.image = Config.image.ic_camera_flash_auto_white
        }
    }
    
    @objc func recordButtonTapped(_ sender: UIButton) {
        self.cameraButton.isEnabled = false
        switch cameraManager.cameraOutputMode {
        case .stillImage:
            cameraManager.capturePictureWithCompletion { result in
                switch result {
                case .failure:
                    self.cameraManager.showErrorBlock("Error occurred", "Cannot save picture.")
                case .success(let content):
                    self.dismiss(animated: true, completion: {
                        if let image = content.asImage {
                            self.delegate?.camera(self, capture: image)
                        }
                    })
                }
                self.cameraButton.isEnabled = true
            }
        case .videoWithMic, .videoOnly:
            cameraButton.isSelected = !cameraButton.isSelected
            cameraButton.setTitle("", for: UIControl.State.selected)
            
            cameraButton.backgroundColor = cameraButton.isSelected ? redColor : lightBlue
            if sender.isSelected {
                cameraManager.startRecordingVideo()
            } else {
                cameraManager.stopVideoRecording { (_, error) -> Void in
                    if error != nil {
                        self.cameraManager.showErrorBlock("Error occurred", "Cannot save video.")
                    }
                }
            }
        }
    }
    
    @objc func locateMeButtonTapped(_ sender: Any) {
        cameraManager.shouldUseLocationServices = true
        locationButton.isHidden = true
    }
    
    @objc func outputModeButtonTapped(_ sender: UIButton) {
        cameraManager.cameraOutputMode = cameraManager.cameraOutputMode == CameraOutputMode.videoWithMic ? CameraOutputMode.stillImage : CameraOutputMode.videoWithMic
        switch cameraManager.cameraOutputMode {
        case .stillImage:
            cameraButton.isSelected = false
            cameraButton.backgroundColor = lightBlue
            outputImageView.image = UIImage(named: "output_image")
        case .videoWithMic, .videoOnly:
            outputImageView.image = UIImage(named: "output_video")
        }
    }
    
    @objc private func changeCameraDevice(_ sender: Any) {
        cameraManager.cameraDevice = cameraManager.cameraDevice == CameraDevice.front ? CameraDevice.back : CameraDevice.front
    }
    
    private func askForCameraPermissions() {
        cameraManager.askUserForCameraPermission { permissionGranted in
            
            if permissionGranted {
                self.addCameraToView()
            } else {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } else {
                    
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @objc private func changeCameraQuality() {
        switch cameraManager.cameraOutputQuality {
        case .high:
            qualityLabel.text = "Medium"
            cameraManager.cameraOutputQuality = .medium
        case .medium:
            qualityLabel.text = "Low"
            cameraManager.cameraOutputQuality = .low
        case .low:
            qualityLabel.text = "High"
            cameraManager.cameraOutputQuality = .high
        default:
            qualityLabel.text = "High"
            cameraManager.cameraOutputQuality = .high
        }
    }
}
extension CameraViewController {
    private func prepareHeaderView()
    {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            headerView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func prepareFooterView()
    {
        NSLayoutConstraint.activate([
            footerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            footerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            footerView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func prepreaFlashImage()
    {
        flashModeImageView.isUserInteractionEnabled = true
        flashModeImageView.isHidden = true
        flashModeImageView.image = Config.image.ic_camera_flash_off
        NSLayoutConstraint.activate([
            flashModeImageView.trailingAnchor.constraint(equalTo: self.headerView.trailingAnchor, constant: -20),
            flashModeImageView.topAnchor.constraint(equalTo: self.headerView.topAnchor, constant: 5),
        ])
    }
    
    private func prepareChangeCamera()
    {
        cameraTypeImageView.isUserInteractionEnabled = true
        cameraTypeImageView.image = Config.image.ic_CameraSwitch_white
        NSLayoutConstraint.activate([
            cameraTypeImageView.trailingAnchor.constraint(equalTo: self.footerView.trailingAnchor, constant: -20),
            cameraTypeImageView.centerYAnchor.constraint(equalTo: self.footerView.centerYAnchor)
        ])
    }
    
    private func preareCameraView()
    {
        cameraView.backgroundColor = .black
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: self.view.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            cameraView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            cameraView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            cameraView.heightAnchor.constraint(equalTo: self.view.heightAnchor)
        ])
    }
    
    private func prepareCameraButton()
    {
        let dummyView = UIButton()
        dummyView.layer.cornerRadius = 30
        dummyView.layer.borderColor = UIColor.black.cgColor
        dummyView.layer.borderWidth = 2
        dummyView.translatesAutoresizingMaskIntoConstraints = false
        dummyView.addTarget(self, action: #selector(recordButtonTapped(_:)), for: .touchUpInside)
        cameraButton.addSubview(dummyView)
        
        
        cameraButton.backgroundColor = .white
        cameraButton.layer.cornerRadius = 35
        NSLayoutConstraint.activate([
            cameraButton.bottomAnchor.constraint(equalTo: self.footerView.bottomAnchor, constant: -10),
            cameraButton.centerXAnchor.constraint(equalTo: self.footerView.centerXAnchor),
            cameraButton.heightAnchor.constraint(equalToConstant: 70),
            cameraButton.widthAnchor.constraint(equalToConstant: 70),
            
            dummyView.centerYAnchor.constraint(equalTo: self.cameraButton.centerYAnchor),
            dummyView.centerXAnchor.constraint(equalTo: self.cameraButton.centerXAnchor),
            dummyView.heightAnchor.constraint(equalToConstant: 60),
            dummyView.widthAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    private func preparBackButton()
    {
        backButton.setImage(Config.image.ic_Back_White, for: .normal)
        backButton.addTarget(self, action: #selector(onTapBack(_:)), for: .touchUpInside)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 10),
            backButton.topAnchor.constraint(equalTo: self.headerView.topAnchor, constant: 5),
            backButton.widthAnchor.constraint(equalToConstant: 20),
            backButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
