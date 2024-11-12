//
//  WXRequestApi.swift
//  WXNetworkingSwift
//
//  Created by CoderMaoWX on 2021/8/20.
//

import Foundation
import Alamofire
import KakaJSON

// 另起别名为了桥接作用
public typealias WXDataRequest = DataRequest
public typealias WXDownloadRequest = DownloadRequest
public typealias WXDictionaryStrAny = Dictionary<String, Any>
public typealias WXAnyObjectBlock = (AnyObject) -> ()
public typealias WXProgressBlock = (Progress) -> Void
public typealias WXNetworkResponseBlock = (WXResponseModel) -> ()

public enum WXRequestSerializerType {
    case EncodingJSON       // application/json
    case EncodingFormURL    // application/x-www-form-urlencoded
}

///全局单例请求 URLSession
fileprivate var WXSession: Session = {
   let sessionConfig = URLSessionConfiguration.default
   sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
   let wxConfig = WXRequestConfig.shared
   if #available(iOS 11.0, *), wxConfig.openMultipathService == true {
       sessionConfig.multipathServiceType = .handover
   }
   if let protocolClasses = wxConfig.urlSessionProtocolClasses {
       sessionConfig.protocolClasses = [ protocolClasses ]
   }
   if wxConfig.forbidProxyCaught == true {
       sessionConfig.connectionProxyDictionary = [ : ]
   }
   let session = Session(configuration: sessionConfig)
   return session
}()

//MARK: - 请求基础对象

///请求基础对象, 外部上不建议直接用，请使用子类请求方法
open class WXBaseRequest: NSObject {
    ///请求Method类型
    fileprivate(set) var requestMethod: HTTPMethod = .post
    ///请求地址
    fileprivate(set) var requestURL: String = ""
    ///请求参数
    fileprivate var parameters: WXDictionaryStrAny? = nil
    ///请求超时，默认30s
    public var timeOut: TimeInterval = 30
    ///请求自定义请求头信息
    public var requestHeaderDict: Dictionary<String, String>? = nil
    ///请求序列化对象 (json, form表单)
    public var requestSerializer: WXRequestSerializerType = .EncodingJSON
    ///请求任务对象
    fileprivate var requestDataTask: Request? = nil
    
    ///初始化方法
    required public init(_ requestURL: String, method: HTTPMethod = .post, parameters: WXDictionaryStrAny? = nil) {
        super.init()
        self.requestMethod = method
        self.requestURL = requestURL
        self.parameters = parameters
    }
    
    deinit {
        //WXRequestTools.WXDebugLog("====== WXBaseRequest 请求对象已释放====== \(self)")
    }
    
    ///底层最终的请求参数 (页面上可实现<WXPackParameters>协议来实现重新包装请求参数)
    lazy var finalParameters: WXDictionaryStrAny? = {
        if conforms(to: WXPackParameters.self) {
            return (self as? WXPackParameters)?.parametersWillTransformFromOriginParamete(parameters: parameters)
        } else {
            return parameters
        }
    }()

    /// 网络请求方法 (不做任何额外处理的原始Alamofire请求，页面上不建议直接用，请使用子类请求方法)
    /// - Parameters:
    ///   - successClosure: 请求成功回调
    ///   - failureClosure: 请求失败回调
    /// - Returns: 求Session对象
    @discardableResult
    public func baseRequestBlock(successClosure: WXAnyObjectBlock?,
                                 failureClosure: WXAnyObjectBlock?) -> WXDataRequest {
        var serializerType: ParameterEncoding = URLEncoding.default
        if requestSerializer == .EncodingJSON {
            serializerType = JSONEncoding.default
        }
        let dataRequest = WXSession.request(requestURL,
                                     method: requestMethod,
                                     parameters: finalParameters,
                                     encoding: serializerType,
                                     headers: HTTPHeaders(requestHeaderDict ?? [:]),
                                     requestModifier: { [weak self] urlRequest in
                                        urlRequest.timeoutInterval = self?.timeOut ?? 60
                                        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
            
                                     }).responseJSON { response in
                                switch response.result {
                                case .success(let json):
                                    successClosure?(json as AnyObject)

                                case .failure(let error):
                                    failureClosure?(error as AnyObject)
                                }
                          }
        requestDataTask = dataRequest
        return dataRequest
    }
    
    /// 上传文件请求
    /// - Parameter responseBlock: 请求回调
    /// - Returns: 请求任务对象(可用来取消任务)
    @discardableResult
    public func baseUploadFile(successClosure: WXAnyObjectBlock?,
                               failureClosure: WXAnyObjectBlock?,
                               formDataClosure: @escaping ((MultipartFormData) -> Void),
                               uploadClosure: @escaping WXProgressBlock) -> WXDataRequest {
        
        let dataRequest = WXSession.upload(
                            multipartFormData: formDataClosure,
                            to: requestURL,
                            method: requestMethod,
                            headers: HTTPHeaders(requestHeaderDict ?? [:]),
                            requestModifier: { [weak self] urlRequest in
                                let time = self?.timeOut ?? 5 * 60
                                urlRequest.timeoutInterval = (time == 30) ? 5 * 60 : time
                                urlRequest.cachePolicy = .reloadIgnoringLocalCacheData

                             }).responseJSON { response in
                                switch response.result {
                                case .success(let json):
                                    successClosure?(json as AnyObject)

                                case .failure(let error):
                                    failureClosure?(error as AnyObject)
                                }
                            }.uploadProgress(closure: uploadClosure)
        
        requestDataTask = dataRequest
        return dataRequest
    }
    
    /// 下载文件请求
    /// - Parameter responseBlock: 请求回调
    /// - Returns: 请求任务对象(可用来取消任务)
    @discardableResult
    public func baseDownloadFile(successClosure: WXAnyObjectBlock?,
                                 failureClosure: WXAnyObjectBlock?,
                                 progressClosure: @escaping WXProgressBlock) -> WXDownloadRequest {
        var serializerType: ParameterEncoding = URLEncoding.default
        if requestSerializer == .EncodingJSON {
            serializerType = JSONEncoding.default
        }
        let dataRequest = WXSession.download(requestURL,
                                             method: requestMethod,
                                             parameters: parameters,
                                             encoding: serializerType,
                                             headers: HTTPHeaders(requestHeaderDict ?? [:]),
                                             requestModifier: { [weak self] urlRequest in
                                                let time = self?.timeOut ?? 5 * 60
                                                urlRequest.timeoutInterval = (time == 30) ? 5 * 60 : time
                                                urlRequest.cachePolicy = .reloadIgnoringLocalCacheData

                                            }).responseData { response in
                                                switch response.result {
                                                case .success(let json):
                                                    successClosure?(json as AnyObject)

                                                case .failure(let error):
                                                    failureClosure?(error as AnyObject)
                                                }
                                         }.downloadProgress(closure: progressClosure)
        
        requestDataTask = dataRequest
        return dataRequest
    }
    
}

//MARK: - 单个请求对象

/// 单个请求对象, 功能根据需求可多种自定义
open class WXRequestApi: WXBaseRequest {
    
    ///请求成功时是否自动缓存响应数据, 默认不缓存
    public var autoCacheResponse: Bool = false
    
    ///自定义请求成功时的缓存数据, (返回的字典为此次需要保存的缓存数据, 返回nil时底层则不缓存)
    public var cacheResponseBlock: ( (WXResponseModel) -> (WXDictionaryStrAny?) )? = nil
    
    ///自定义解析成功时的响应数据, (例如: 在请求成功后 需要解密响应的json结果后才能真正获取成功标识, 解析模型等等..)
    public var decryptHandlerResponse: ((AnyObject) -> AnyObject)? = nil
    
    ///自定义请求成功映射Key/Value, (key可以是KeyPath模式进行匹配 如: data.status)
    ///注意: 每个请求状态优先使用此属性判断, 如果此属性值为空, 则再取全局的 TSNetworkConfig.successStatusMap的值进行判断
    public var successStatusMap: (key: String, value: String)? = nil

    ///请求成功时自动解析数据模型映射:keyPath/ModelType, (key可以是KeyPath模式进行匹配 如: data.returnData)
    ///成功解析的模型在 WXResponseModel.parseModel 中返回
    public var parseModelMap: (keyPath: String, modelType: Convertible.Type)? = nil
    
    ///times: 请求失败之后重新请求次数, delay: 每次重试的间隔
    public var retryWhenFailTuple: (times: Int, delay: Double)? = nil
    
    /// [⚠️仅DEBUG模式生效⚠️] 作用:方便开发时调试接口使用,设置的值可为以下4种:
    /// 1. json String: 则不会请求网络, 直接响应回调此json值
    /// 2. Dictionary: 则不会请求网络, 直接响应回调此Dictionary值
    /// 3. local file path: 则直接读取当前本地的path的json文件内容
    /// 4. http(s) path: 则直接请求当前设置的模拟接口地址
    public var debugJsonResponse: Any? = nil

    ///请求转圈的父视图
    public weak var loadingSuperView: UIView? = nil
    
    ///自动配置: 上传文件Data元祖 (与下面的 uploadFileManualConfigBlock 二选一即可)
    public var uploadFileDataTuple: (withName: String, dataArr: [ Data ])? = nil
    
    ///手动配置: 自定义上传时数据回调  (与上面的 uploadFileDataTuple 二选一即可)
    public var uploadFileManualConfigBlock: ( (MultipartFormData) -> Void )? = nil
    
    ///监听上传/下载进度
    public var fileProgressBlock: WXProgressBlock? = nil
    
    ///网络请求过程多链路回调<将要开始, 将要停止, 已经完成>
    /// 注意: 如果没有实现此代理则会回调单例中的全局代理<globleMulticenterDelegate>
    public var multicenterDelegate: WXNetworkMulticenter? = nil
    
    ///可以用来添加几个accossories对象 来做额外的插件等特殊功能
    ///如: (请求HUD, 加解密, 自定义打印, 上传统计)
    public var requestAccessories: [WXNetworkMulticenter]? = nil
    
    ///Xcode控制台显示日志信息 (printf: 是否打印在Xcode控制台, hostTitle: 打印的环境名称 如 测试环境/正式环境...)
    /// 注意此属性优先级大于全局单例(WXRequestConfig.urlResponseLogTuple)的优先级
    public var urlResponseLogTuple: (printf: Bool, hostTitle: String?)? = nil
    
    ///以下为私有属性,外部可以忽略
    fileprivate var retryCount: Int = 0
    fileprivate var requestDuration: Double = 0
    fileprivate lazy var apiUniquelyIp: String = {
        let address = Unmanaged.passUnretained(self).toOpaque()
        return "\(address)"
    }()
    
    ///初始化方法
    required public init(_ requestURL: String, method: HTTPMethod = .post, parameters: WXDictionaryStrAny? = nil) {
        super.init(requestURL, method: method, parameters: parameters)
    }

    deinit {
        //WXRequestTools.WXDebugLog("====== WXRequestApi 请求对象已释放====== \(self)")
    }
    
    //MARK: - 网络请求入口
    
    /// 开始网络请求
    /// - Parameter responseBlock: 请求回调
    /// - Returns: 请求任务对象(可用来取消任务)
    @discardableResult
    public func startRequest(responseBlock: ((_ response: WXResponseModel) -> ())?) -> WXDataRequest? {
        apiType = .noraml
        
        var isDebugJson = false
#if DEBUG
        if let debugJsonURL = debugJsonResponse as? String, debugJsonURL.hasPrefix("http") {
            requestURL = debugJsonURL
            isDebugJson = true
        }
#endif
        guard let _ = URL(string: requestURL) else {
            configResponseBlock(responseBlock: responseBlock, responseObj: nil)
            return nil
        }
        cancelTheSameOldRequest()
        let networkBlock: WXAnyObjectBlock = { [weak self] responseObj in
            if isDebugJson, var debugRespDict = responseObj as? WXDictionaryStrAny {
                debugRespDict[ kWXNetworkDebugResponseKey ] = true
                self?.configResponseBlock(responseBlock: responseBlock, responseObj: (debugRespDict as AnyObject))
            } else {
                self?.configResponseBlock(responseBlock: responseBlock, responseObj: responseObj)
            }
        }
        readRequestCacheWithBlock(fetchCacheBlock: networkBlock)
        
#if DEBUG
        if let debugJsonDict = responseForDebugJson() {
            isDebugJson = true
            networkBlock(debugJsonDict as AnyObject)
            return nil
        }
#endif
        handleMulticenter(type: .WillStart, responseModel: WXResponseModel())
        //开始请求
        let dataRequest = baseRequestBlock(successClosure: networkBlock, failureClosure: networkBlock)
        return dataRequest
    }
    
    /// 上传文件请求
    /// - Parameter responseBlock: 请求回调
    /// - Returns: 请求任务对象(可用来取消任务)
    @discardableResult
    public func uploadFile(responseBlock: WXNetworkResponseBlock?) -> WXDataRequest? {
        apiType = .upload
        
        guard let _ = URL(string: requestURL) else {
            configResponseBlock(responseBlock: responseBlock, responseObj: nil)
            return nil
        }
        
        let networkBlock: WXAnyObjectBlock = { [weak self] responseObj in
            self?.configResponseBlock(responseBlock: responseBlock, responseObj: responseObj)
        }
        
        handleMulticenter(type: .WillStart, responseModel: WXResponseModel())
        //开始文件上传
        let dataRequest = baseUploadFile(
                        successClosure: networkBlock,
                        failureClosure: networkBlock,
                        formDataClosure: { [weak self] multipartFormData in
                            //手动配置上传数据
                            if let multipartFormDataHandle = self?.uploadFileManualConfigBlock {
                                multipartFormDataHandle( multipartFormData )
                                
                            } else if let uploadFileTuple = self?.uploadFileDataTuple, uploadFileTuple.dataArr.count > 0 { //自动配置上传数据
                                for fileData in uploadFileTuple.dataArr {
                                    let dataInfo = WXRequestTools.dataMimeType(for: fileData)
                                    let name = (dataInfo.mimeType as NSString).deletingLastPathComponent
                                    /// 生成一个随机的上传文件名称
                                    let fileName = name + "-\(Int(Date().timeIntervalSince1970))" + "." + dataInfo.fileType
                                    multipartFormData.append(fileData, withName: uploadFileTuple.withName, fileName: fileName, mimeType: dataInfo.mimeType)
                                }
                            }
                            //拼接上传参数
                            if let parameters = self?.parameters, parameters.count > 0 {
                                for (key, value) in parameters {
                                    if let valueString = value as? String {
                                        let paramData = valueString.data(using: String.Encoding.utf8)
                                        multipartFormData.append(paramData!, withName: key.description)
                                    }
                                }
                            }
                        },
                        uploadClosure: { [weak self] in
                            self?.fileProgressBlock?($0)
                        })
        return dataRequest
    }
    
    /// 下载文件请求
    /// - Parameter responseBlock: 请求回调
    /// - Returns: 请求任务对象(可用来取消任务)
    @discardableResult
    public func downloadFile(responseBlock: @escaping WXNetworkResponseBlock) -> WXDownloadRequest? {
        apiType = .download
        
        guard let _ = URL(string: requestURL) else {
            configResponseBlock(responseBlock: responseBlock, responseObj: nil)
            return nil
        }

        let networkBlock: WXAnyObjectBlock = { [weak self] responseObj in
            self?.configResponseBlock(responseBlock: responseBlock, responseObj: responseObj)
        }
        
        handleMulticenter(type: .WillStart, responseModel: WXResponseModel())
        
        //开始文件下载
        let dataRequest = baseDownloadFile(successClosure: networkBlock,
                                           failureClosure: networkBlock,
                                           progressClosure: { [weak self] in
            self?.fileProgressBlock?($0)
        })
        return dataRequest
    }

    //MARK: - 处理请求响应
    
    ///DEBUG调试配置数据读取
    fileprivate func responseForDebugJson() -> WXDictionaryStrAny? {
        if let rspJsonDict = debugJsonResponse as? WXDictionaryStrAny {
            return rspJsonDict
            
        } else if var debugJsonString = debugJsonResponse as? String, debugJsonString.hasPrefix("http") == false {
            // is local file string ?
            if FileManager.default.fileExists(atPath: debugJsonString) {
                debugJsonString = (try? String(contentsOfFile:debugJsonString, encoding: .utf8)) ?? ""
                
            } else if let jsonPath = Bundle.main.path(forResource: debugJsonString, ofType: nil) {
                debugJsonString = (try? String(contentsOfFile:jsonPath, encoding: .utf8)) ?? ""
            }
            // jsonString -> Dictionary
            return WXRequestTools.jsonToDictionary(jsonString: debugJsonString)
        }
        return nil
    }
    
    fileprivate func configResponseBlock(responseBlock: WXNetworkResponseBlock?, responseObj: AnyObject?) {
        let responseModel = configResponseModel(responseObj: responseObj)
        responseBlock?(responseModel)
        handleMulticenter(type: .DidCompletion, responseModel: responseModel)

        // code = 15 (isExplicitlyCancelledError): is manual cancelled
        if let retryTuple = retryWhenFailTuple, retryCount < retryTuple.times,
           let error = responseObj as? AFError, error.isExplicitlyCancelledError == false {
            
            DispatchQueue.main.asyncAfter(deadline: (.now() + retryTuple.delay)) {
                self.retryCount += 1
                self.startRequest(responseBlock: responseBlock)
            }
        }
    }
    
    ///配置数据响应回调模型
    fileprivate func configResponseModel(responseObj: AnyObject?) -> WXResponseModel {
        let rspModel = WXResponseModel()
        rspModel.responseDuration = getCurrentTimestamp() - requestDuration
        rspModel.apiUniquelyIp = apiUniquelyIp
        rspModel.responseObject = responseObj
        rspModel.urlRequest = requestDataTask?.request
        rspModel.urlResponse = requestDataTask?.response
        
        if let error = responseObj as? NSError { // Fail (NSError, AFError, Error都可相互转换)
            rspModel.error = error
            rspModel.responseCode = error.code
            rspModel.responseMsg = configFailMessage

        } else if responseObj == nil { // Fail
            rspModel.error = NSError(domain: configFailMessage, code: -444, userInfo: nil)
            rspModel.responseCode = rspModel.error?.code
            rspModel.responseMsg = configFailMessage
            
        } else { //Success
            var handleResponse = responseObj!
            //需要解密响应的json结果吗?
            if let handleBlock = decryptHandlerResponse {
                handleResponse = handleBlock(handleResponse)
            }
            let responseDict = packagingResponseObj(responseObj: handleResponse, responseModel: rspModel)
            rspModel.responseDict = responseDict
            
            //检查请求成功状态
            checkingSuccessStatus(responseDict: responseDict, rspModel: rspModel)

            if rspModel.isSuccess {
                rspModel.parseResponseKeyPathModel(requestApi: self, responseDict: responseDict)
            }
        }
        handleMulticenter(type: .WillStop, responseModel: rspModel)
        return rspModel
    }
    
    fileprivate func packagingResponseObj(responseObj: AnyObject, responseModel: WXResponseModel) -> WXDictionaryStrAny {
        var responseDcit: [String : Any] = [:]
        if let rspObj = responseObj as? WXDictionaryStrAny {
            responseDcit = rspObj
            
            responseDcit[ kWXNetworkDebugResponseKey ].map({
                responseDcit.removeValue(forKey: kWXNetworkDebugResponseKey)
                responseModel.isDebugResponse = $0 as! Bool
            })
            if let _ = responseDcit[kWXRequestDataFromCacheKey] {
                responseDcit.removeValue(forKey: kWXRequestDataFromCacheKey)
                responseModel.isCacheData = true
            }
        } else if responseObj is Data {
            if let rspData = responseObj.mutableCopy() as? Data {
                responseModel.responseObject = rspData as AnyObject
                responseDcit["response"] = "Binary Data, length: \(rspData.count)"
            }
        } else if let jsonString = responseObj as? String { // jsonString -> Dictionary
            if let jsonDict = WXRequestTools.jsonToDictionary(jsonString: jsonString) {
                return jsonDict
            } else {
                responseDcit["response"] = jsonString
            }
        } else if let response = responseObj.description {
            responseDcit["response"] = response
        }
        return responseDcit
    }

    ///检查请求成功状态
    fileprivate func checkingSuccessStatus(responseDict: WXDictionaryStrAny, rspModel: WXResponseModel) {
        if let successKeyValue = successStatusMap ?? WXRequestConfig.shared.successStatusMap {
            let matchKey: String = successKeyValue.key
            let mapSuccessValue: String = successKeyValue.value
            
            //默认采用直接查找匹配请求成功标识
            var responseCode: Any? = responseDict[matchKey]

            // 如果包含点(.)连接,则采用KeyPath模式查找匹配请求成功标识
            if matchKey.contains(".") {
                var lastMatchValue: Any? = responseDict
                for tmpKey in matchKey.components(separatedBy: ".") {
                    if lastMatchValue == nil {
                        break
                    } else { //寻找匹配请求成功的关键字典
                        lastMatchValue = findAppositeDict(matchKey: tmpKey, respValue: lastMatchValue)
                    }
                }
                //匹配到请求成功自定义key对应的Value
                responseCode = lastMatchValue
            }
            
            if let stringCode = responseCode as? String {
                rspModel.isSuccess = (stringCode == mapSuccessValue)
                rspModel.responseCode = Int(stringCode)

            } else if let numberCode = responseCode as? NSNumber  {
                rspModel.isSuccess = (numberCode.stringValue == mapSuccessValue)
                rspModel.responseCode = Int(numberCode.stringValue)
            }
        }
        //取返回的提示信息
        if let msgTipKeyOrFailInfo = WXRequestConfig.shared.messageTipKeyAndFailInfo {
            if let responseMsg = responseDict[ (msgTipKeyOrFailInfo.tipKey) ] as? String {
                rspModel.responseMsg = responseMsg
            }
        }
        //如果失败时没有返回Msg,则填一个全局默认提示信息
        if rspModel.isSuccess == false {
            if rspModel.responseMsg == nil {
                rspModel.responseMsg = configFailMessage
            }
            let domain = rspModel.responseMsg ?? KWXRequestFailueDefaultMessage
            let code = rspModel.responseCode ?? -444
            rspModel.error = NSError(domain: domain, code: code, userInfo: responseDict)
        }
    }
    
    ///寻找最合适的解析: 字典/数组
    fileprivate func findAppositeDict(matchKey: String, respValue: Any?) -> Any? {
        if let respDict = respValue as? WXDictionaryStrAny {
            for (dictKey, dictValue) in respDict {
                if matchKey == dictKey {
                    return dictValue
                }
            }
        }
        return nil
    }
    
    fileprivate var apiType: WXRequestApiType = .noraml
    fileprivate enum WXRequestApiType: String {
        case noraml = "请求"
        case upload = "上传"
        case download = "下载"
    }
    ///网络请求过程多链路回调
    fileprivate func handleMulticenter(type: WXRequestMulticenterType,
                                       responseModel: WXResponseModel) {
        
        var delegate: WXNetworkMulticenter?
        if let tmpDelegate = multicenterDelegate {
            delegate = tmpDelegate
        } else {
            delegate = WXRequestConfig.shared.globleMulticenterDelegate
        }
        
        switch type {
        case .WillStart:
            Self.judgeLoadingShow(true, toView: loadingSuperView)
            requestDuration = getCurrentTimestamp()
            WXRequestConfig.shared.globleRequestList.append(self)
            
            // start request log tip
            if self.urlResponseLogTuple?.printf ?? false ||
                WXRequestConfig.shared.urlResponseLogTuple.printf {
                var typeName = apiType.rawValue
                if retryCount == 0 {
                    typeName = apiType == .noraml ? "" : typeName
                    WXRequestTools.WXDebugLog("\n👉👉👉已发出\(typeName)网络请求=", requestURL)
                } else {
                    WXRequestTools.WXDebugLog("\n👉👉👉\(typeName)失败,第【 \(retryCount) 】次尝试重新\(typeName)请求=", requestURL)
                }
            }
            
            delegate?.requestWillStart(request: self)
            if let requestAccessories = requestAccessories {
                for accessory in requestAccessories {
                    accessory.requestWillStart(request: self)
                }
            }
            
        case .WillStop:
            Self.judgeLoadingShow(false, toView: loadingSuperView)
            
            if URL(string: requestURL) == nil {
                let typeName = apiType.rawValue
                WXRequestTools.WXDebugLog("\n❌❌❌无效的 URL \(typeName)地址= \(requestURL)")
            }
            
            guard responseModel.isCacheData == false else { return }
            printfResponseLog(responseModel: responseModel)
            
            delegate?.requestWillStop(request: self, responseModel: responseModel)
            if let requestAccessories = requestAccessories {
                for accessory in requestAccessories {
                    accessory.requestWillStop(request: self, responseModel: responseModel)
                }
            }
            
        case .DidCompletion:
            checkPostNotification(responseModel: responseModel)
            
            delegate?.requestDidCompletion(request: self, responseModel: responseModel)
            if let requestAccessories = requestAccessories {
                for accessory in requestAccessories {
                    accessory.requestDidCompletion(request: self, responseModel: responseModel)
                }
            }
            
            if responseModel.isCacheData {
                printfResponseLog(responseModel: responseModel)
            } else {
                // save cache as much as possible at the end
                saveResponseObjToCache(responseModel: responseModel)
                
                // remove current request task
                WXRequestConfig.shared.globleRequestList.removeAll(where: { $0 == self })
                
                // upload network log
                WXRequestTools.uploadNetworkResponseJson(request: self, responseModel: responseModel)
            }
        }
    }
    
    ///打印网络响应日志到控制台
    fileprivate func printfResponseLog(responseModel: WXResponseModel) {
#if DEBUG
        if let urlResponseLogTuple = self.urlResponseLogTuple {
            if urlResponseLogTuple.printf == false { return }
        } else {
            guard WXRequestConfig.shared.urlResponseLogTuple.printf else { return }
        }
        let logHeader = WXRequestTools.appendingPrintfLogHeader(request: self, responseModel: responseModel)
        let logFooter = WXRequestTools.appendingPrintfLogFooter(responseModel: responseModel)
        WXRequestTools.WXDebugLog("\(logHeader + logFooter)")
#endif
    }
    
    ///检查是否需要发出通知
    fileprivate func checkPostNotification(responseModel: WXResponseModel) {
        let notifyDict = WXRequestConfig.shared.codeNotifyDict
        if let responseCode = responseModel.responseCode, let notifyDict = notifyDict {
            for (key, value) in notifyDict where responseCode == value {
                NotificationCenter.default.post(name: NSNotification.Name(key), object: responseModel)
            }
        }
    }
    
    fileprivate func getCurrentTimestamp() -> Double {
        let dat = NSDate.init(timeIntervalSinceNow: 0)
        return dat.timeIntervalSince1970 * 1000
    }
    
    ///添加请求转圈
    fileprivate static func judgeLoadingShow(_ show: Bool, toView: UIView?) {
        guard WXRequestConfig.shared.showRequestLaoding else { return }
        guard let loadingSuperView = toView else { return }
        if show {
            WXRequestTools.showLoading(to: loadingSuperView)
        } else {
            WXRequestTools.hideLoading(from: loadingSuperView)
        }
    }
    
    ///失败默认提示
    fileprivate var configFailMessage: String {
        if let msgTipKeyOrFailInfo = WXRequestConfig.shared.messageTipKeyAndFailInfo {
            return msgTipKeyOrFailInfo.defaultTip
        }
        return KWXRequestFailueDefaultMessage
    }
    
    ///检查是否有相同请求在请求, 有则取消旧的请求
    fileprivate func cancelTheSameOldRequest() {
        for request in WXRequestConfig.shared.globleRequestList {
            let oldJson = WXRequestTools.dictionaryToJSON(dictionary: request.finalParameters)
            let oldReq = request.requestURL + request.requestMethod.rawValue + (oldJson ?? "")
            
            let newJson = WXRequestTools.dictionaryToJSON(dictionary: finalParameters)
            let newReq = requestURL + requestMethod.rawValue + (newJson ?? "")
            
            if oldReq == newReq {
                request.requestDataTask?.cancel()
                //注意:这里不能立即break退出遍历,因为取消后可能不会立马回调
            }
        }
    }
    
    lazy var cacheKey: String = {
        if cacheResponseBlock != nil || autoCacheResponse {
            let parameterJson = WXRequestTools.dictionaryToJSON(dictionary: finalParameters)
            let originValue = requestURL + requestMethod.rawValue + (parameterJson ?? "")
            return WXRequestTools.convertToMD5(originStr: originValue)
        }
        return ""
    }()

    ///如果本地需要有缓存: 则读取接口本地缓存数据返回
    fileprivate func readRequestCacheWithBlock(fetchCacheBlock: @escaping WXAnyObjectBlock) {
        if cacheResponseBlock != nil || autoCacheResponse {
            
            DispatchQueue.global().async {
                var cachePath = WXRequestTools.fetchCachePath() ///缓存目录
                cachePath = (cachePath as NSString).appendingPathComponent(self.cacheKey)
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: cachePath), let cacheData = fileManager.contents(atPath: cachePath) {
                    if let cacheJsonStr = String(data: cacheData, encoding: .utf8) {
                        if var cacheDcit = WXRequestTools.jsonToDictionary(jsonString: cacheJsonStr) {
                            cacheDcit[kWXRequestDataFromCacheKey] = true
                            DispatchQueue.main.async {
                                fetchCacheBlock(cacheDcit as AnyObject)
                            }
                        }
                    }
                }
            }
        }
    }
    
    ///保存接口响应数据到本地缓存
    fileprivate func saveResponseObjToCache(responseModel: WXResponseModel) {
        var saveRspJson: String? = nil
        
        if let cacheBlock = cacheResponseBlock, responseModel.isSuccess,
           let saveResponseDict = cacheBlock(responseModel) {
            if let responseJson = WXRequestTools.dictionaryToJSON(dictionary: saveResponseDict) {
                saveRspJson = responseJson
            }
        } else if autoCacheResponse, let responseDict = responseModel.responseDict {
            if let responseJson = WXRequestTools.dictionaryToJSON(dictionary: responseDict) {
                saveRspJson = responseJson
            }
        }
        
        if let saveJson = saveRspJson {
            DispatchQueue.global().async {
                var cachePath = WXRequestTools.fetchCachePath() ///缓存目录
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: cachePath) == false {
                    try? fileManager.createDirectory(atPath: cachePath, withIntermediateDirectories: true)
                }
                cachePath = (cachePath as NSString).appendingPathComponent(self.cacheKey)
                try? saveJson.write(toFile: cachePath, atomically: true, encoding: .utf8)
            }
        }
    }
}

//MARK: - 批量请求对象

///批量请求对象, 可以
open class WXBatchRequestApi {
    
    ///全部请求是否都成功了
    public var isAllSuccess: Bool = false
    
    ///全部响应数据, 按请求requestArray的Api添加顺序排序返回
    public var responseDataArray: [WXResponseModel] = []
    
    ///全部请求对象, 响应时Api按添加顺序返回
    fileprivate var requestArray: [WXRequestApi]
    ///请求转圈的父视图
    fileprivate(set) var loadingSuperView: UIView? = nil
    
    
    //以下内部私有属性, 外部请忽略
    fileprivate var batchRequest: WXBatchRequestApi? = nil //避免提前释放当前对象
    fileprivate var responseBatchBlock: ((WXBatchRequestApi) -> ())? = nil
    fileprivate var responseInfoDict: Dictionary<String, WXResponseModel> = [:]
    
    ///初始化器
    required public init(apiArray: [WXRequestApi], loadingTo superView: UIView? = nil) {
        self.requestArray = apiArray
        self.loadingSuperView = superView
    }

    deinit {
        //WXRequestTools.WXDebugLog("====== WXBatchRequestApi 请求对象已释放====== \(self)")
    }

    /// 批量网络请求: (实例方法:Block回调方式)
    /// - Parameters:
    ///   - responseBlock: 请求完成后响应回调
    ///   - waitAllDone: 是否等待全部请求完成才回调, 否则回调多次
    public func startRequest(_ responseBlock: @escaping (WXBatchRequestApi) -> (),
                      waitAllDone: Bool = true) {
        
        responseDataArray.removeAll()
        batchRequest = self
        responseBatchBlock = responseBlock
        if requestArray.count > 0 {
            WXRequestApi.judgeLoadingShow(true, toView: loadingSuperView)
        }
        for api in requestArray {
            
            api.loadingSuperView = nil
            api.startRequest { [weak self] responseModel in
                //配置响应数据
                self?.configAllResponseData(responseModel: responseModel)
                
                if waitAllDone {
                    self?.finalHandleBatchResponse(responseModel: responseModel)
                } else { //回调多次
                    self?.oftenHandleBatchResponse(responseModel: responseModel)
                }
            }
        }
    }
    
    ///配置响应数据
    fileprivate func configAllResponseData(responseModel: WXResponseModel) {
        //本地有缓存, 当前请求失败了就不保存当前失败RspModel,则使用缓存
        let apiUniquelyIp = responseModel.apiUniquelyIp
        if responseInfoDict[apiUniquelyIp] == nil || responseModel.responseDict != nil {
            responseInfoDict[apiUniquelyIp] = responseModel
        }
        // 请求最终回调数据: 按请求对象添加顺序排序
        responseDataArray = requestArray.compactMap {
            responseInfoDict[ $0.apiUniquelyIp ]
        }
    }
    
    ///标记是否都成功: 一个失败就标记不是都成功
    fileprivate func refreshIsAllSuccess() {
        var success = false
        for respModel in responseDataArray where respModel.isCacheData == false {
            if respModel.responseDict == nil {
                success = false//一个失败就标记不是都成功
                break
            } else {
                success = true
            }
        }
        isAllSuccess = success
    }
    
    ///待所有请求都响应才回调到页面
    fileprivate func finalHandleBatchResponse(responseModel: WXResponseModel) {
        if responseModel.isCacheData == false, responseDataArray.count >= requestArray.count {
            refreshIsAllSuccess()
            WXRequestApi.judgeLoadingShow(false, toView: loadingSuperView)
            
            if let responseBatchBlock = responseBatchBlock {
                responseBatchBlock(self)
            }
            batchRequest = nil
        }
    }
    
    ///每次请求响应都回调到页面
    fileprivate func oftenHandleBatchResponse(responseModel: WXResponseModel) {
        if responseModel.isCacheData == false, responseDataArray.count >= requestArray.count {
            refreshIsAllSuccess()
        }
        WXRequestApi.judgeLoadingShow(false, toView: loadingSuperView)
        
        if let responseBatchBlock = responseBatchBlock {
            responseBatchBlock(self)
        }
        if responseModel.isCacheData == false, responseDataArray.count >= requestArray.count {
            batchRequest = nil
        }
    }
    
    ///根据请求获取指定的响应数据
    public func responseForRequest(request: WXRequestApi) -> WXResponseModel? {
        return responseInfoDict[request.apiUniquelyIp]
    }
    
    /// 取消所有请求
    public func cancelAllRequest() {
        for request in requestArray {
            request.requestDataTask?.cancel()
        }
    }
    
}

//MARK: - 请求响应对象

///包装的响应数据
public class WXResponseModel: NSObject {
    /**
     * 是否请求成功,优先使用 WXRequestApi.successStatusMap 来判断是否成功
     * 否则使用 TSNetworkConfig.successStatusMap 标识来判断是否请求成功
     ***/
    public var isSuccess: Bool = false
    ///本次响应Code码
    public var responseCode: Int? = nil
    ///本次响应的提示信息 (页面可直接用于Toast提示,
    ///如果接口有返回messageTipKeyAndFailInfo.tipKey则会取这个值, 如果没有返回则取defaultTip的默认值)
    public var responseMsg: String? = nil
    ///本次数据是否为缓存
    public var isCacheData: Bool = false
    ///请求耗时(毫秒)
    public var responseDuration: TimeInterval? = nil
    ///解析数据的模型: 可KeyPath匹配, 返回 Model对象 或者 模型数组 [Model]
    public var parseModel: AnyObject? = nil
    ///本次响应的原始数据: NSDictionary/ UIImage/ NSData /...
    public var responseObject: AnyObject? = nil
    ///本次响应的原始字典数据
    public var responseDict: WXDictionaryStrAny? = nil
    ///本次响应的数据是否为Debug测试数据
    public var isDebugResponse: Bool = false
    ///失败时的错误信息
    public var error: NSError? = nil
    ///原始响应
    public var urlResponse: HTTPURLResponse? = nil
    ///原始请求
    public var urlRequest: URLRequest? = nil
    
//    fileprivate var apiUniquelyIp: String = "\(String(describing: "\(self)"))"
    fileprivate lazy var apiUniquelyIp: String = {
        let address = Unmanaged.passUnretained(self).toOpaque()
        return "\(address)"
    }()
    
    ///解析响应数据的数据模型 (支持KeyPath匹配)
    fileprivate func parseResponseKeyPathModel(requestApi: WXRequestApi,
                                               responseDict: WXDictionaryStrAny) {
        guard let parseModelMap = requestApi.parseModelMap else { return }
        
        let parseKey: String = parseModelMap.keyPath
        guard parseKey.count > 0 else { return }
        let modelCalss = parseModelMap.modelType
        
        var lastValueDict: Any?
        if parseKey.contains(".") {
            let keyPathArr = parseKey.components(separatedBy: ".")
            lastValueDict = responseDict
            
            for modelKey in keyPathArr {
                if lastValueDict == nil {
                    return
                } else { //寻找最合适的解析: 字典/数组
                    lastValueDict = requestApi.findAppositeDict(matchKey: modelKey, respValue: lastValueDict)
                }
            }
        } else {
            lastValueDict = responseDict[parseKey]
        }
        if let customModelValue = lastValueDict as? WXDictionaryStrAny {
            parseModel = customModelValue.kj.model(type: modelCalss) as AnyObject
            
        }  else if let modelObj = lastValueDict as? Array<Any> {
            parseModel = modelObj.kj.modelArray(type: modelCalss) as AnyObject
        }
    }

}
