//
//  WXRequestTools.swift
//  WXNetworkingSwift
//
//  Created by CoderMaoWX on 2021/8/21.
//

import Foundation
import UIKit
import CommonCrypto

let kLoadingHUDTag = 7987

public class WXRequestTools {
    
    //MARK: - 全局打印日志方法
    public static func WXDebugLog(_ message: Any...,
                                  file: String = #file,
                                  function: String = #function,
                                  lineNumber: Int = #line) {
#if DEBUG
        //let fileName = (file as NSString).lastPathComponent
        //print("[\(fileName):funciton:\(function):line:\(lineNumber)]- \(message)")
        
        var appdengLog: String = ""
        var idx = message.count
        for log in message {
            appdengLog += "\(log)" + ( (idx != 1) ? " " : "" )
            idx -= 1
        }
        //print("[\(fileName): line:\(lineNumber)]", appdengLog)
        print(appdengLog)
#endif
    }
    
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
        var logFooter = dictionaryToJSON(dictionary: responseModel.responseDict)
        //去除URL中的反斜杠
        logFooter = logFooter?.replacingOccurrences(of: "\\/", with: "/")
        var body = catchTag + logHeader + (logFooter ?? "")
        //var body = catchTag + logHeader + "点击 👆【查看格式化详情】👆查看响应Json日志"
        body = body.replacingOccurrences(of: "\n", with: "<br>")
        
        //(目前此方法供内部使用, 因此以下参数固定写死,
        // 如果外部需要使用,可实现: <WXNetworkMulticenter>协议, 自己处理上传日志的操作)
        var uploadInfo: [String: Any] = [:]
        uploadInfo["level"]            = "iOS"
        uploadInfo["appName"]          = appName
        uploadInfo["version"]          = version
        uploadInfo["body"]             = body
        uploadInfo["platform"]         = "\(appName)-iOS-"
        uploadInfo["device"]           = UIDevice.current.model
        uploadInfo["feeTime"]          = "\(responseModel.responseDuration ?? 0)"
        uploadInfo["timestamp"]        = formatter.string(from: Date())
        uploadInfo["url"]              = request.requestURL
        uploadInfo["request"]          = requestJson
        uploadInfo["requestHeader"]    = responseModel.urlRequest?.allHTTPHeaderFields ?? [:]
        uploadInfo["response"]         = (responseModel.responseDict == nil) ? responseModel.error.debugDescription : responseModel.responseDict
        uploadInfo["responseHeader"]   = responseModel.urlResponse?.allHeaderFields ?? [:]
        
        let baseRequest = WXBaseRequest(uploadURL, method: .post, parameters: uploadInfo)
        baseRequest.requestSerializer = .EncodingJSON
        baseRequest.baseRequestBlock(successClosure: nil, failureClosure: nil)
    }
    
    
    /// 打印日志头部
    /// - Parameters:
    ///   - request: 响应模型
    ///   - responseModel: 请求对象
    /// - Returns: 日志头部字符串
    public static func appendingPrintfLogHeader(request: WXRequestApi,
                                                responseModel: WXResponseModel) -> String {
        let isSuccess   = responseModel.isSuccess
        let isCacheData = responseModel.isCacheData
        let requestJson = dictionaryToJSON(dictionary: request.finalParameters) ?? "{}"
        let hostTitle = WXRequestConfig.shared.urlResponseLogTuple.hostTitle.map {"【\($0)】"} ?? ""
        let requestHeaders = responseModel.urlRequest?.allHTTPHeaderFields ?? request.requestHeaderDict ?? [:]
        let headersJson = dictionaryToJSON(dictionary: requestHeaders)
        let headersString = (requestHeaders.count > 0) ? "\n\n请求头信息＝\(headersJson ?? "")" : ""
        let statusFlag = isCacheData ? "❤️❤️❤️" : (isSuccess ? "✅✅✅" : "❌❌❌")
        let dataType = responseModel.isDebugResponse ? "【Debug】数据" : "网络数据"
        let statusString  = isCacheData ? "本地缓存数据成功" : (isSuccess ? "\(dataType)成功" : "\(dataType)失败");
        let feeTime = "（⤵️耗时:\(Int(responseModel.responseDuration ?? 0))ms）"
        let method = responseModel.urlRequest?.method?.rawValue ?? responseModel.urlRequest?.httpMethod ?? ""
        return """
            
            \(statusFlag)请求接口地址\(hostTitle)＝\(request.requestURL)
            
            \(method) 请求参数json＝\(requestJson)\(headersString)
            
            \(statusString)返回＝\(feeTime)
            
            """
    }
    
    
    /// 打印日志尾部
    /// - Parameter responseModel: 响应模型
    /// - Returns: 日志头部字符串
    public static func appendingPrintfLogFooter(responseModel: WXResponseModel, prettify: Bool = true) -> String {
        if let responseDict = responseModel.responseDict {
            let options = (prettify == true) ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization
                .WritingOptions()
            
            let jsonData = try? JSONSerialization.data(withJSONObject: responseDict, options: options)
            var responseJson = responseDict.description
            if let jsonData = jsonData {
                responseJson = String(data: jsonData, encoding: .utf8) ?? responseJson
            }
            //去除URL中的反斜杠
            responseJson = responseJson.replacingOccurrences(of: "\\/", with: "/")
            return responseJson
        } else {
            let errorDescription = responseModel.error?.description ?? ""
            if let localizedDesc = responseModel.error?.localizedDescription {
                return """
                       \(errorDescription)
                       \(localizedDesc)
                       """
            } else {
                return errorDescription
            }
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
        let cachePath = cacheDirectory.appendingPathComponent(kWXNetworkResponseCache)
        return cachePath
    }
    
    // MARK: 字典/JSON字符串相互转化
    /// 字典转换为JSON String
    public static func dictionaryToJSON(dictionary: WXDictionaryStrAny?) -> String? {
        guard let dictionary = dictionary else { return nil }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            WXDebugLog("Failed to convert dictionary to JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// JSON String转换为字典
    public static func jsonToDictionary(jsonString: String) -> WXDictionaryStrAny? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        if let jsonDict = (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)) as? WXDictionaryStrAny {
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
    public static func hideLoading(from superView: UIView) {
        let hideLoadingBlock = { (loadingSuperView: UIView ) in
            for tmpView in loadingSuperView.subviews where tmpView.tag == kLoadingHUDTag {
                tmpView.removeFromSuperview()
            }
        }
        if Thread.isMainThread {
            hideLoadingBlock(superView)
        } else {
            DispatchQueue.main.async {
                hideLoadingBlock(superView)
            }
        }
    }
    
    /// 指定视图上显示loading框
    /// - Parameter paramater: loading框的父视图
    public static func showLoading(to loadingSuperView: UIView) {
        
        let showLoadingBlock = { (loadingSuperView: UIView) in
            hideLoading(from: loadingSuperView)
            
            let screenMaskView = UIView(frame: loadingSuperView.bounds)
            screenMaskView.backgroundColor = .clear
            screenMaskView.tag = kLoadingHUDTag
            loadingSuperView.addSubview(screenMaskView)
            
            let maskBgViewDic = ["maskBgView" : screenMaskView]
            loadingSuperView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[maskBgView]-0-|", metrics: nil, views: maskBgViewDic))
            
            loadingSuperView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[maskBgView]-0-|", metrics: nil, views: maskBgViewDic))
            
            let maskWidth = screenMaskView.bounds.size.width
            let maskHeight = screenMaskView.bounds.size.height
            var HUDWidth: CGFloat = 72.0
            var HUDHeight: CGFloat = 72.0
            
            let HUDView: UIView
            //show custom loading
            if let hudClass = WXRequestConfig.shared.requestHUDClass {
                HUDView = hudClass.init()
                var rect = HUDView.frame
                HUDWidth = rect.size.width
                if HUDWidth == 0 { HUDWidth = 72.0 }
                HUDHeight = rect.size.height
                if HUDHeight == 0 { HUDHeight = 72.0 }
                rect.origin.x = (maskWidth - HUDWidth) / 2.0
                rect.origin.y = (maskHeight - HUDHeight) / 2.0
                HUDView.frame = rect
                screenMaskView.addSubview(HUDView)
                
            } else {
                let x = (maskWidth - HUDWidth) / 2.0
                let y = (maskHeight - HUDHeight) / 2.0
                HUDView = UIView(frame: CGRect(x: x, y: y, width: HUDWidth, height: HUDHeight))
                HUDView.translatesAutoresizingMaskIntoConstraints = false
                HUDView.layer.masksToBounds = true
                HUDView.layer.cornerRadius = 12
                HUDView.backgroundColor = .init(white: 0, alpha: 0.7)
                screenMaskView.addSubview(HUDView)
                
                var activityView: UIActivityIndicatorView
                if #available(iOS 13.0, *) {
                    activityView = UIActivityIndicatorView(style: .large)
                } else {
                    activityView = UIActivityIndicatorView(style: .whiteLarge)
                }
                activityView.color = .white
                activityView.hidesWhenStopped = true
                activityView.startAnimating()
                activityView.center = CGPoint(x: HUDWidth/2, y: HUDHeight/2)
                HUDView.addSubview(activityView)
            }
            
            var result: [NSLayoutConstraint] = []
            let viewDic = ["indicatorBg" : HUDView]
            result.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[indicatorBg(\(HUDWidth))]", metrics: nil, views: viewDic))
            result.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[indicatorBg(\(HUDHeight))]", metrics: nil, views: viewDic))
            screenMaskView.addConstraints(result)
            screenMaskView.addConstraint(NSLayoutConstraint(item: HUDView, attribute: .centerY, relatedBy: .equal, toItem: screenMaskView, attribute: .centerY, multiplier: 1, constant: 0))
            
            screenMaskView.addConstraint(NSLayoutConstraint(item: HUDView, attribute: .centerX, relatedBy: .equal, toItem: screenMaskView, attribute: .centerX, multiplier: 1, constant: 0))
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

