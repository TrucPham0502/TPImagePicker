//
//  Config.swift
//  TPImagePicker
//
//  Created by Truc Pham on 25/05/2021.
//

import Foundation
import UIKit
struct Config {
    struct image {
        static let ic_camera_gallery = UIImage(named: "ic_camera_gallery")
        static let ic_camera_flash_off = UIImage(named: "ic_camera_flash_off")
        static let ic_camera_flash_on_white = UIImage(named: "ic_camera_flash_on_white")
        static let ic_camera_flash_auto_white = UIImage(named: "ic_camera_flash_auto_white")
        static let ic_CameraSwitch_white = UIImage(named: "ic_CameraSwitch_white")
        static let ic_Back_White = UIImage(named: "ic_Back_White")
        static let ic_down_white = UIImage(named: "ic_down_white")
        static let video_icon = UIImage(named: "video_icon")
        static let check_on = UIImage(named: "check_on")
        static let single_check_on = UIImage(named: "single_check_on")
        static let check_off = UIImage(named: "check_off")
        static let live_photos = UIImage(named: "live_photos")
       
        
    }
    
    struct color {
        static let onBackgroundTertiaryLevel = UIColor(named: "onBackgroundTertiaryLevel")
        static let backgroundTertiary = UIColor(named: "backgroundTertiary")
        static let onBackgroundDisable = UIColor(named: "onBackgroundDisable")
    }
    
    struct language {
        static let shotcut = "shotcut"
        static let send_Photo = "send_Photo"
        static let permission_button_ok = "permission_button_ok"
        static let permission_button_cancel = "permission_button_cancel"
        static let permission_dialog_title = "permission_dialog_title"
        static let permission_dialog_message = "permission_dialog_message"
        static let context_menu_title = "Main Menu"
        
    }
}
