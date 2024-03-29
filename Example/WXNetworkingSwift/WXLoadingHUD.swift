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
        addSubview(indicatorView)
        indicatorView.startAnimating()
    }
    
    lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .whiteLarge)
        indicatorView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        indicatorView.color = .red
        return indicatorView
    }()

    
    
}
