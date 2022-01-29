//
//  WXLoadingHUD.swift
//  WXNetworkingSwift_Example
//
//  Created by 610582 on 2022/1/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class WXLoadingHUD: UIView {

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        initSubView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func initSubView() {
        backgroundColor = .clear
        addSubview(imageView)
    }
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "loading"))
        imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
}
