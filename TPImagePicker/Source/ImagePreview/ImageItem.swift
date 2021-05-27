import UIKit

enum ImageItem {
    case image(UIImage?)
    case asset(PhotoAsset?, placeholder: UIImage?)
    case url(URL, placeholder: UIImage?)
}
