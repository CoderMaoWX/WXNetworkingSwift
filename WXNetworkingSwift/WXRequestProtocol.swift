//
//  WXNetworkConstr.swift
//  WXNetworkingSwift
//
//  Created by CoderMaoWX on 2021/8/20.
//

import Foundation

let KWXUploadAppsFlyerStatisticsKey = "KWXUploadAppsFlyerStatisticsKey"
let kWXNetworkResponseCache         = "kWXNetworkResponseCache"
let kWXNetworkIsTestResponseKey     = "kWXNetworkIsTestResponseKey"
let KWXRequestFailueDefaultMessage  = "Loading failed, please try again later."
let kWXRequestDataFromCacheKey      = "WXNetwork_DataFromCacheKey"

enum WXRequestMulticenterType: Int {
    case WillStart
    case WillStop
    case DidCompletion
}

@objc protocol WXPackParameters {
    
    /// 外部可包装最终网络底层最终请求参数
    /// - Parameter parameters: 默认外部传进来的<parameters>
    /// - return 网络底层最终的请求参数
    func parametersWillTransformFromOriginParamete(parameters: Dictionary<String, Any>?) -> Dictionary<String, Any>
}

///网络请求过程多链路回调
public protocol WXNetworkMulticenter {
    
    /// 网络请求将要开始回调
    /// - Parameter request: 请求对象
    func requestWillStart(request: WXRequestApi)
    
    
    /// 网络请求回调将要停止 (包括成功或失败)
    /// - Parameters:
    ///   - request: 请求对象
    ///   - responseModel: 响应对象
    func requestWillStop(request: WXRequestApi, responseModel: WXResponseModel)
    
    
    /// 网络请求已经回调完成 (包括成功或失败)
    /// - Parameters:
    ///   - request: 请求对象
    ///   - responseModel: 响应对象
    func requestDidCompletion(request: WXRequestApi, responseModel: WXResponseModel)
    
}


public protocol WXNetworkDelegate {
    
    /// 网络请求数据响应回调
    /// - Parameters:
    ///   - request: 请求对象
    ///   - responseModel: 响应对象
    func wxResponseWithRequest(request: WXRequestApi, responseModel: WXResponseModel)
}
