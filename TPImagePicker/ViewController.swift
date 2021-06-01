//
//  ViewController.swift
//  TPImagePicker
//
//  Created by Truc Pham on 25/05/2021.
//

import UIKit

class ViewController: UIViewController {

    private lazy var buttonShow : UIButton = {
        let v = UIButton()
        v.setTitle("show", for: .normal)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.addTarget(self, action: #selector(buttonShowTap), for: .touchUpInside)
        v.backgroundColor = .red
        return v
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(buttonShow)
        NSLayoutConstraint.activate([
            buttonShow.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            buttonShow.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            buttonShow.widthAnchor.constraint(equalToConstant: 100)
        ])
        // Do any additional setup after loading the view.
        
    }
    
    @objc
    func buttonShowTap(_ sender : Any?){
        let vc = TPImagePickerViewController()
        vc.maxSelect = 5
        vc.numberOfColumns = 3
        vc.selectMode = .multiple
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    

}

