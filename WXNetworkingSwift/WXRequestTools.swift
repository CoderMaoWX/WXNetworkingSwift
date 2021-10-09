//
//  WXRequestTools.swift
//  WXNetworkingSwift
//
//  Created by 610582 on 2021/8/21.
//

import Foundation
import UIKit
import CommonCrypto

let kLoadingHUDTag = 7987

//MARK: - 全局打印日志方法
public func WXDebugLog(_ message: Any...,
              file: String = #file,
              function: String = #function,
              lineNumber: Int = #line) {
    #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        //print("[\(fileName):funciton:\(function):line:\(lineNumber)]- \(message)")
    
        var appdengLog: String = ""
        var idx = message.count
        for log in message {
            appdengLog += "\(log)" + ( (idx != 1) ? " " : "" )
            idx -= 1
        }
        print("[\(fileName): line:\(lineNumber)]", appdengLog)
    #endif
}

public class WXRequestTools {
    
    /// 上传网络日志到服装日志系统入口 (目前此方法供内部使用)
    /// - Parameters:
    ///   - request: 响应模型
    ///   - responseModel: 请求对象
    public static func uploadNetworkResponseJson(request: WXRequestApi,
                                   responseModel: WXResponseModel) {
        if responseModel.isCacheData { return }
        let configu = WXRequestConfig.shared
        if configu.isDistributionOnlineRelease { return }
        
        guard let tuple = configu.uploadRequestLogTuple, let uploadURL = tuple.url, let _ = URL(string: uploadURL) else { return }
        
        guard let catchTag = tuple.catchTag, catchTag.count > 0 else { return }
        
        var requestJson = request.finalParameters
        
        if let _ = request.finalParameters?[KWXUploadAppsFlyerStatisticsKey] {
            guard configu.printfStatisticsLog else { return }
            requestJson?.removeValue(forKey: KWXUploadAppsFlyerStatisticsKey)
        }
        
        let bundleInfo = Bundle.main.infoDictionary
        let appName = bundleInfo?[kCFBundleExecutableKey as String] ?? bundleInfo?[kCFBundleIdentifierKey as String] ?? ""
        
        let version = bundleInfo?["CFBundleShortVersionString"] ?? bundleInfo?[kCFBundleVersionKey as String] ?? ""
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmssSSS"
        formatter.timeZone = NSTimeZone.local
        
        let logHeader = appendingPrintfLogHeader(request: request, responseModel: responseModel)
        let logFooter = dictionaryToJSON(dictionary: responseModel.responseDict)
        var body = logHeader + (logFooter ?? "")
        body = body.replacingOccurrences(of: "\n", with: "<br>")
        
        var uploadInfo: Dictionary<String, Any> = [:]
        uploadInfo["level"]            = "iOS"
        uploadInfo["appName"]          = appName
        uploadInfo["version"]          = version
        uploadInfo["body"]             = body
        uploadInfo["platform"]         = "\(appName)-iOS-\(catchTag)"
        uploadInfo["device"]           = UIDevice.current.model
        uploadInfo["feeTime"]          = "\(responseModel.responseDuration ?? 0)"
        uploadInfo["timestamp"]        = formatter.string(from: Date())
        uploadInfo["url"]              = request.requestURL
        uploadInfo["request"]          = requestJson
        uploadInfo["requestHeader"]    = responseModel.urlRequest?.allHTTPHeaderFields ?? [:]
        uploadInfo["response"]         = responseModel.responseDict ?? [:]
        uploadInfo["responseHeader"]   = responseModel.urlResponse?.allHeaderFields ?? [:]
        
        let baseRequest = WXBaseRequest(uploadURL, method: .post, parameters: uploadInfo)
        baseRequest.baseRequestBlock(successClosure: nil, failureClosure: nil)
    }


    /// 打印日志头部
    /// - Parameters:
    ///   - request: 响应模型
    ///   - responseModel: 请求对象
    /// - Returns: 日志头部字符串
    public static func appendingPrintfLogHeader(request: WXRequestApi,
                                  responseModel: WXResponseModel) -> String {
        let isSuccess   = (responseModel.responseDict == nil) ? false : true
        let isCacheData = responseModel.isCacheData
        let requestJson = dictionaryToJSON(dictionary: request.finalParameters) ?? "{}"
        let hostTitle = WXRequestConfig.shared.urlResponseLogTuple.hostTitle ?? ""
        let requestHeaders = responseModel.urlRequest?.allHTTPHeaderFields ?? [:]
        let headersJson = dictionaryToJSON(dictionary: requestHeaders)
        let headersString = (requestHeaders.count > 0) ? "\n\n请求头信息= \(headersJson ?? "")" : ""
        let statusFlag = isCacheData ? "❤️❤️❤️" : (isSuccess ? "✅✅✅" : "❌❌❌")
        let dataType = responseModel.isTestResponse ? "测试数据" : "网络数据"
        let statusString  = isCacheData ? "本地缓存数据成功" : (isSuccess ? "\(dataType)成功" : "\(dataType)失败");
		return """

			\(statusFlag)请求接口地址\(hostTitle)= \(request.requestURL)

			请求参数json= \(requestJson)\(headersString)

			\(statusString)返回=

			"""
    }


    /// 打印日志尾部
    /// - Parameter responseModel: 响应模型
    /// - Returns: 日志头部字符串
    public static func appendingPrintfLogFooter(responseModel: WXResponseModel) -> String {
        if let responseDict = responseModel.responseDict {
            let jsonData = try? JSONSerialization.data(withJSONObject: responseDict, options: .prettyPrinted)
            
            var responseJson = responseDict.description
            if let jsonData = jsonData {
                responseJson = String(data: jsonData, encoding: .utf8) ?? responseJson
            }
            return responseJson
        } else {
            return responseModel.error?.description ?? ""
        }
    }

    ///获取文件的 mimeType 类型
    public static func dataMimeType(for data: Data) -> (mimeType: String, fileType: String) {
        var b: UInt8 = 0
        data.copyBytes(to: &b, count: 1)
        switch b {
        case 0xFF:
            return ("image/jpeg", "jpeg")
        case 0x89:
            return ("image/png", "png")
        case 0x47:
            return ("image/gif", "gif")
        case 0x4D, 0x49:
            return ("image/tiff", "tiff")
        case 0x25:
            return ("application/pdf", "pdf")
        case 0xD0:
            return ("application/vnd", "vnd")
        case 0x46:
            return ("text/plain", "file")
        default:
            return ("application/octet-stream", "stream")
        }
    }
    
    ///缓存目录
    internal static func fetchCachePath() -> String {
        let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last! as NSString
        var cachePath = cacheDirectory.appendingPathComponent(kWXNetworkResponseCache)
        return cachePath
    }
    
    // MARK: 字典/JSON字符串相互转化
    /// 字典转换为JSONString
    public static func dictionaryToJSON(dictionary: Dictionary<String, Any>?) -> String? {
        guard let dictionary = dictionary else {
            return nil
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions()) {
            let jsonStr = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            return String(jsonStr ?? "")
        }
        return nil
    }
    
    /// JSONString转换为字典
    public static func jsonToDictionary(jsonString: String) -> Dictionary<String, Any>? {
        if let jsonDict = (try? JSONSerialization.jsonObject(with: jsonString.data(using: String.Encoding.utf8, allowLossyConversion: true)!, options: JSONSerialization.ReadingOptions.mutableContainers)) as? WXDictionaryStrAny {
            return jsonDict
        }
        return nil
    }
    
    ///转换MD5值
    public static func convertToMD5(originStr: String) -> String {
        let str = originStr.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(originStr.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        free(result)
        return String(format: hash as String)
    }
    
    
    //MARK: - 请求转圈弹框
    
    /// 隐藏指定视图上的loading框
    /// - Parameter view: 指定视图参数
    public static func hideLoading(from view: UIView) {
        let hideLoadingBlock: ( (UIView) -> () ) = { loadingSuperView in
            for tmpView in loadingSuperView.subviews where tmpView.tag == kLoadingHUDTag {
                tmpView.removeFromSuperview()
            }
        }
        if Thread.isMainThread {
            hideLoadingBlock(view)
        } else {
            DispatchQueue.main.async {
                hideLoadingBlock(view)
            }
        }
    }
    
    /// 指定视图上显示loading框
    /// - Parameter paramater: loading框的父视图
    public static func showLoading(to loadingSuperView: UIView) {

        let showLoadingBlock: ((UIView)->()) = { loadingSuperView in
            hideLoading(from: loadingSuperView)
            
            let maskBgView = UIView(frame: loadingSuperView.bounds)
            maskBgView.backgroundColor = .clear
            maskBgView.tag = kLoadingHUDTag
            loadingSuperView.addSubview(maskBgView)
            
            let maskBgViewDic = ["maskBgView" : maskBgView]
            loadingSuperView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[maskBgView]-0-|",
                                                                           metrics: nil,
                                                                           views: maskBgViewDic))
            
            loadingSuperView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[maskBgView]-0-|",
                                                                           metrics: nil,
                                                                           views: maskBgViewDic))
            let HUDSize: CGFloat = 72.0
            let x = (maskBgView.bounds.size.width - HUDSize) / 2.0
            let y = (maskBgView.bounds.size.height - HUDSize) / 2.0
            
            let indicatorBg = UIView(frame: CGRect(x: x, y: y, width: HUDSize, height: HUDSize))
            indicatorBg.translatesAutoresizingMaskIntoConstraints = false
            indicatorBg.layer.masksToBounds = true
            indicatorBg.layer.cornerRadius = 12
            indicatorBg.backgroundColor = .init(white: 0, alpha: 0.7)
            maskBgView.addSubview(indicatorBg)
            
            var result: [NSLayoutConstraint] = []
            let viewDic = ["indicatorBg" : indicatorBg]
            result.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[indicatorBg(72)]",
                                                                     metrics: nil,
                                                                     views: viewDic))
            result.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[indicatorBg(72)]",
                                                                     metrics: nil,
                                                                     views: viewDic))
            maskBgView.addConstraints(result)
            maskBgView.addConstraint(NSLayoutConstraint(item: indicatorBg,
                                                        attribute: .centerY,
                                                        relatedBy: .equal,
                                                        toItem: maskBgView,
                                                        attribute: .centerY,
                                                        multiplier: 1,
                                                        constant: 0))
            
            maskBgView.addConstraint(NSLayoutConstraint(item: indicatorBg,
                                                        attribute: .centerX,
                                                        relatedBy: .equal,
                                                        toItem: maskBgView,
                                                        attribute: .centerX,
                                                        multiplier: 1,
                                                        constant: 0))
            var loadingView: UIActivityIndicatorView
            if #available(iOS 13.0, *) {
                loadingView = UIActivityIndicatorView(style: .large)
            } else {
                loadingView = UIActivityIndicatorView(style: .whiteLarge)
            }
            loadingView.color = .white
            loadingView.hidesWhenStopped = true
            loadingView.startAnimating()
            loadingView.center = CGPoint(x: HUDSize/2, y: HUDSize/2)
            indicatorBg.addSubview(loadingView)
        }

        if Thread.isMainThread {
            showLoadingBlock(loadingSuperView)
        } else {
            DispatchQueue.main.async {
                showLoadingBlock(loadingSuperView)
            }
        }
    }
}

