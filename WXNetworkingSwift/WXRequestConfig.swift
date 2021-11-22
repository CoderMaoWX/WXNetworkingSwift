//
//  WXRequestConfig.swift
//  WXNetworkingSwift
//
//  Created by Luke on 2021/8/20.
//

import Foundation
import KakaJSON

///请求库全局配置信息
public class WXRequestConfig {
    
    ///约定全局请求成功映射: key/value (注意: 优先使用WXRequestApi中的successStatusMap来判断)
    ///(key可以是KeyPath模式进行匹配 如: (key: "data.status", value: "200")
    public var successStatusMap: (key: String, value: String)? = nil
    
    ///约定全局请求的提示tipKey, 返回值会保存在: WXResponseModel.responseMsg中
    ///如果接口没有返回此key 或者HTTP连接失败时 则取defaultTip当做通用提示文案, 页面直接取responseMsg当作通用提示即可
    public var messageTipKeyAndFailInfo: (tipKey: String, defaultTip: String)? = nil
    
    ///请求遇到相应Code时触发通知 (可设置多个key/Vlaue, 如: [ "notificationName" : 200 ])
    ///例如适用于监听全局处理等操作, 例: Token失效重新登录...
    public var codeNotifyDict: Dictionary<String, Int>? = nil
    
    /**
     * 是否需要全局管理 网络请求过程多链路回调<将要开始, 将要完成, 已经完成>
     * 注意: 此全局代理与单个请求对象中的<multicenterDelegate>代理互斥, 两者都实现时优先回调单个请求对象中的代理
     */
    public var globleMulticenterDelegate: WXNetworkMulticenter? = nil

    ///全局网络请求拦截类代理 (提示: 一定要放在首次发请求之前才生效)
    public var urlSessionProtocolClasses: AnyClass? = nil

    ///是否禁止所有的网络请求设置代理抓包 (警告: 一定要放在首次发请求之前设值(例如+load方法中), 默认不禁止)
    public var forbidProxyCaught: Bool = false

    ///是否打开多路径TCP服务，提供Wi-Fi和蜂窝之间的无缝切换，(默认关闭)(提示: 一定要放在首次发请求之前才生效)
    public var openMultipathService: Bool = false

    ///请求HUD时的类名
    public var requestHUDCalss: UIView? = nil
    
    ///是否显示请求HUD,全局开关, 默认显示
    public var showRequestLaoding: Bool = true
    
    ///是否为正式上线环境: 如果为真,则下面的所有日志上传/打印将全都被忽略
    public var isDistributionOnlineRelease: Bool = false
    
    ///Xcode控制台显示日志信息 (printf: 是否打印在Xcode控制台, hostTitle: 打印的环境名称 如 测试环境/正式环境...)
    public var urlResponseLogTuple: (printf: Bool, hostTitle: String?) = (true, nil)
    
    ///url:全局请求日志上传到指定的URL(如日志系统), catchTag:查看日志的标识
    ///注意: url和catchTag都不为空时才上传
    public var uploadRequestLogTuple: (url: String?, catchTag: String?)? = nil

    /**
     * 是否打印统计上传日志，默认不打印
     * (如果是统计日志发出的请求则请在请求参数中带有key: KWXUploadAppsFlyerStatisticsKey)
     * */
    public var printfStatisticsLog: Bool = false

    ///单利对象
    public static let shared = WXRequestConfig()
    private init() {
	}
    
    ///清除所有缓存
    public func clearWXNetworkAllRequestCache(completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            var cachePath = WXRequestTools.fetchCachePath()
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: cachePath) {
                try? fileManager.removeItem(atPath: cachePath)
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }
    }
    
    ///清除指定缓存
    public func clearWXNetworkCacheOfRequest(serverApi: WXRequestApi, completion: @escaping (Bool)->()) {
        DispatchQueue.global().async {
            var cachePath = WXRequestTools.fetchCachePath()
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: cachePath) {
                let deletePath = (cachePath as NSString).appendingPathComponent(serverApi.cacheKey)
                try? fileManager.removeItem(atPath: deletePath)
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }
    }
    
}

