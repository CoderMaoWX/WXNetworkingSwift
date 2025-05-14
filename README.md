# WXNetworkingSwift

 [OC版本的见这里](https://github.com/CoderMaoWX/WXNetworking)

[![CI Status](https://img.shields.io/travis/maowangxin/WXNetworkingSwift.svg?style=flat)](https://travis-ci.org/maowangxin/WXNetworkingSwift)
[![Version](https://img.shields.io/cocoapods/v/WXNetworkingSwift.svg?style=flat)](https://cocoapods.org/pods/WXNetworkingSwift)
[![License](https://img.shields.io/cocoapods/l/WXNetworkingSwift.svg?style=flat)](https://cocoapods.org/pods/WXNetworkingSwift)
[![Platform](https://img.shields.io/cocoapods/p/WXNetworkingSwift.svg?style=flat)](https://cocoapods.org/pods/WXNetworkingSwift)

## 简介

有没有遇到过这样一种情况，每次在项目中使用请求库去请求数据时，各种小功能需要自己在每个请求里面单独去开发，比如请求缓存、请求HUD、设置请求头、设置失败重试机制、判断是否请求成功、请求个性化打印日志、控制批量请求、页面请求重复写数据转模型......, 甚至使用了很久的第三方网络某一天不维护了，导致项目那里面每个页面到处直接使用的Api更换起来简直就是灾难，面对这种情况特意 底层基于``Alamofire``库 封装一套支持高度扩展多功能的网络请求库，即使以后更换底层请求库也很方便，后续也会不断维护更新各种小功能，目前支持的主要功能如下：

### 功能列表: 
- [x] 1、自定义请求头；简单配置请求头或加密头

- [x] 2、自动处理是否缓存；设置缓存机制，自动失效时间等

- [x] 3、请求失败自定义多次重试；支持失败后每隔几秒尝试再试请求，如启动App后一定要请求的必要数据接口。

- [x] 4、支持上传接口抓包日志；如上传到公司内部日志服务器系统上，供测试人员排查问题或快速抓包排查问题。

- [x] 5、极简上传下载文件监听; 简单配置监听上传下载文件进度。

- [x] 6、支持全局/单个配置请求成功后keyPath模型映射；页面上无需每个接口编写解析字典转模型的重新代码，支持数组和自定义模型；

- [x] 7、约定全局请求的提示Hud ToastKey；支持单个配置或全局配置请求失败时的HUD Toast自动弹框提示。

- [x] 8、请求遇到相应Code时触发通知；如：Token失效全部重新登录等;

- [x] 9、网络请求过程多链路回调管理；如：请求将要开始回调，请求回调将要停止，请求已经回调完成;

- [x] 10、格式化打印网络日志；输出日志一目了然，如：请求接口地址、参数、请求头、耗时、响应;

- [x] 11、批量请求；支持自定义每个请求的所有配置，并且可配置等待全部完成才回调还是一起完成才回调;

- [x] 12、支持debug模式不请求网络快速调试模拟接口响应数据；如：本地json string，Dictionary，local json file(桌面路径仅限模拟器调试，http(s)地址), http test url

  . . . . . .（持续完善-ing）

## 使用环境
> iOS, swift 5.0

## 安装方式

WXNetworkingSwift is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```
pod 'WXNetworkingSwift'
```

## 用法

**可灵活配置的基础请求对象**

```
///请求基础对象, 外部上不建议直接用，请使用子类请求方法
open class WXBaseRequest: NSObject {
    ///请求Method类型
    fileprivate (set) var requestMethod: HTTPMethod = .post
    ///请求地址
    fileprivate (set) var requestURL: String = ""
    ///请求参数
    fileprivate var parameters: WXDictionaryStrAny? = nil
    ///请求超时，默认30是
    public var timeOut: TimeInterval = 30
    ///请求自定义头信息
    public var requestHeaderDict: Dictionary<String, String>? = nil
    ///请求序列化对象 (json, form表单)
    public var requestSerializer: WXRequestSerializerType = .EncodingJSON
    ///请求任务对象
    fileprivate var requestDataTask: Request? = nil
    
    ///请求方法见源码
}
```


**可灵活配置的单个请求对象：**

```

/// 单个请求对象, 功能根据需求可多种自定义
open class WXRequestApi: WXBaseRequest {
    
    ///请求成功时是否自动缓存响应数据, 默认不缓存
    public var autoCacheResponse: Bool = false
    
    ///自定义请求成功时的缓存数据, (返回的字典为此次需要保存的缓存数据, 返回nil时底层则不缓存)
    public var cacheResponseBlock: ( (WXResponseModel) -> (WXDictionaryStrAny?) )? = nil
    
    ///自定义解析成功时的响应数据, (例如: 在请求成功后 需要解密响应的json结果后才能真正获取成功标识, 解析模型等等..)
    public var decryptHandlerResponse: ((AnyObject) -> AnyObject)? = nil
    
    ///自定义请求成功映射Key/Value, (key可以是KeyPath模式进行匹配 如: data.status)
    ///注意: 每个请求状态优先使用此属性判断, 如果此属性值为空, 则再取全局的 WXNetworkConfig.successStatusMap的值进行判断
    public var successStatusMap: (key: String, value: String)? = nil

    ///请求成功时自动解析数据模型映射:Key/ModelType, (key可以是KeyPath模式进行匹配 如: data.returnData)
    ///成功解析的模型在 WXResponseModel.parseKeyPathModel 中返回
    public var parseModelMap: (parseKey: String, modelType: Convertible.Type)? = nil
    
    ///times: 请求失败之后重新请求次数, delay: 每次重试的间隔
    public var retryWhenFailTuple: (times: Int, delay: Double)? = nil
    
    /// [⚠️仅DEBUG模式生效⚠️] 作用:方便开发时调试接口使用,设置的值可为以下4种:
    /// 1. json String: 则不会请求网络, 直接响应回调此json值
    /// 2. Dictionary: 则不会请求网络, 直接响应回调此Dictionary值
    /// 3. local file path: 则直接读取当前本地(桌面路径/http(s)地址)的path文件内容(仅限模拟器调试)
    /// 4. http(s) path: 则直接请求当前设置的path
    public var debugJsonResponse: Any? = nil

    ///请求转圈的父视图
    public var loadingSuperView: UIView? = nil
    
    ///上传文件Data数组
    public var uploadFileDataArr: [ Data ]? = nil
    
    ///自定义上传时包装的数据Data对象
    public var uploadConfigDataBlock: ( (MultipartFormData) -> Void )? = nil
    
    ///监听上传/下载进度
    public var fileProgressBlock: WXProgressBlock? = nil
    
    ///网络请求过程多链路回调<将要开始, 将要停止, 已经完成>
    /// 注意: 如果没有实现此代理则会回调单例中的全局代理<globleMulticenterDelegate>
    public var multicenterDelegate: WXNetworkMulticenter? = nil
    
    ///可以用来添加几个accossories对象 来做额外的插件等特殊功能
    ///如: (请求HUD, 加解密, 自定义打印, 上传统计)
    public var requestAccessories: [WXNetworkMulticenter]? = nil
    
    ///请求方法见源码
}
```



**请求响应对象的丰富信息**

```
//MARK: - 请求响应对象

///包装的响应数据
public class WXResponseModel: NSObject {
    /**
     * 是否请求成功,优先使用 WXRequestApi.successStatusMap 来判断是否成功
     * 否则使用 WXNetworkConfig.successStatusMap 标识来判断是否请求成功
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
    ///解析数据的模型: 可KeyPath匹配, 返回 Model对象 或者数组模型 [Model]
    public var parseKeyPathModel: AnyObject? = nil
    ///本次响应的原始数据: NSDictionary/ UIImage/ NSData /...
    public var responseObject: AnyObject? = nil
    ///本次响应的原始字典数据
    public var responseDict: WXDictionaryStrAny? = nil
    ///本次响应的数据是否为Debug测试数据 (读取电脑文件路径时仅限模拟器调试)
    public var isDebugResponse: Bool = false
    ///失败时的错误信息
    public var error: NSError? = nil
    ///原始响应
    public var urlResponse: HTTPURLResponse? = nil
    ///原始请求
    public var urlRequest: URLRequest? = nil
}
```

可灵活配置的批量请求对象：

```
///批量请求对象, 可以
open class WXBatchRequestApi {
    
    ///全部请求是否都成功了
    public var isAllSuccess: Bool = false
    
    ///全部响应数据, 按请求requestArray的Api添加顺序排序返回
    public var responseDataArray: [WXResponseModel] = []
    
    ///全部请求对象, 响应时Api按添加顺序返回
    fileprivate var requestArray: [WXRequestApi]
    ///请求转圈的父视图
    fileprivate (set) var loadingSuperView: UIView? = nil
    
    ///请求方法见源码
}
```

## **1.单个请求示例**
    
```
func testRequest() {
        let url = "http://123.207.32.32:8000/home/multidata"
        let api = WXRequestApi(url, method: .get)
        api.timeOut = 40 //设置超时时间
        api.loadingSuperView = view //请求loading HUD
        api.autoCacheResponse = true //是否需要缓存
        api.requestHeaderDict = [:] //设置请求自定义头信息
        api.successStatusMap = (key: "returnCode",  value: "SUCCESS") //设置请求成功标识key(支持keyPath)
        api.parseModelMap = (parseKey: "data.dKeyword", modelType: DKeywordModel.self)  //设置请求成功模型解析(支持keyPath)
        api.retryWhenFailTuple = (times: 3, delay: 2.0) //设置请求失败重试机制
        api.multicenterDelegate = self //网络请求过程多链路回调<将要开始, 将要停止, 已经完成>
        
        //设置自定义解析成功时的响应数据
        api.decryptHandlerResponse = { (response: AnyObject) -> AnyObject in
            // 自定义解析数据
        }
        //设置自定义请求成功时的缓存数据
        api.cacheResponseBlock = { WXResponseModel -> WXDictionaryStrAny? in
            //自定义缓存
        }
        
        requestTask = api.startRequest { [weak self] responseModel in
            if responseModel.isSuccess {
                self?.textView.text = responseModel.parseKeyPathModel?.description
            } else {
                self?.textView.text = responseModel.responseMsg
            }
        }
    }
```

## **2.批量请求示例**
    
```
func testBatchRequest() {
        let url1 = "https://httpbin.org/get"
        let api1 = WXRequestApi(url1, method: .get)
        api1.autoCacheResponse = true
        
        let url2 = "https://httpbin.org/delay/5"
        let para2: [String : Any] = ["name" : "张三"]
        let api2 = WXRequestApi(url2, method: .get, parameters: para2)
        
        let api = WXBatchRequestApi(apiArray: [api1, api2], loadingTo: view)
        api.startRequest({ [weak self] batchApi in
            print("批量请求回调", batchApi.responseDataArray)
            self?.textView.text = batchApi.responseForRequest(request: api1)?.responseDict?.description
            
        }, waitAllDone: true)
    }
```
## **3.Json请求解析模型示例**
    
```
func testParseModel() {
        let url = "http://app.u17.com/v3/appV3_3/ios/phone/comic/boutiqueListNew"
        let param: [String : Any] = ["sexType" : 1]

        let api = WXRequestApi(url, method: .get, parameters: param)
//        api.debugJsonResponse = "http://10.8.41.162:8090/app/activity/page/detail/92546"  //http（ s ） test URL
//        api.debugJsonResponse = "/Users/xinGe/Desktop/test.json"                          //Desktop json file (仅限模拟器调试)
//        api.debugJsonResponse = "test.json"                                               //Bundle json file
//        api.debugJsonResponse = ["code" : "1", "data" : ["message" : "测试字典"]]          //Dictionary Object
//        api.debugJsonResponse =
//"""
//        {"data":{"message":"成功","stateCode":1,"returnData":{"galleryItems":[],"comicLists":[{"comics":[{"subTitle":"少年 搞笑","short_description":"突破次元壁的漫画！","is_vip":4,"cornerInfo":"190","comicId":181616,"author_name":"壁水羽","cover":"https://cover-oss.u17i.com/2021/07/12647_1625125865_1za73F2a4fD1.sbig.jpg","description":"漫画角色发现自己生活在一个漫画的笼子里，于是奋起反抗作者，面对角色的不配合，作者不得已要不断更改题材，恐怖，魔幻，励志轮番上阵，主角们要一一面对，全力通关","name":"笼中人","tags":["少年","搞笑"]}],"comicType":6,"sortId":"86","newTitleIconUrl":"https://image.mylife.u17t.com/2017/07/10/1499657929_N7oo9pPOhaYH.png","argType":3,"argValue":8,"titleIconUrl":"https://image.mylife.u17t.com/2017/08/29/1503986106_7TY5gK000yjZ.png","itemTitle":"强力推荐作品","description":"更多","canedit":0,"argName":"topic"}],"textItems":[],"editTime":"0"}},"code":1}
//"""

        api.timeOut = 40
        api.loadingSuperView = view
        api.autoCacheResponse = false
        api.retryWhenFailTuple = (times: 3, delay: 1.0)
        api.successStatusMap = (key: "code", value: "1")
        // api.parseModelMap = (parseKey: "data.returnData.comicLists", modelType: ComicListModel.self)

        requestTask = api.startRequest { [weak self] responseModel in
            self?.textView.backgroundColor = .groupTableViewBackground
            if let rspData = responseModel.responseObject as? Data {
                if let image = UIImage(data: rspData) {
                    self?.textView.backgroundColor = .init(patternImage: image)
                }
            }
        }
    }
```

## **4.上传文件示例**
    
```
func testUploadFile() {
        let url = "http://10.8.31.5:8090/uploadImage"
        let param = [
            "appName" : "TEST",
            "platform" : "iOS",
            "version" : "7.3.3",
        ]
        let api = WXRequestApi(url, method: .post, parameters: param)
        api.loadingSuperView = view
        api.retryWhenFailTuple = (times: 3, delay: 3.0)
        api.successStatusMap = (key: "code", value: "200")
        
        let image = UIImage(named: "womenPic")!
        let imageData = UIImagePNGRepresentation(image)
        
        api.uploadFileDataArr = [imageData!]
        api.uploadConfigDataBlock = { multipartFormData in
            multipartFormData.append(imageData!, withName: "files", fileName: "womenPic.png", mimeType: "image/png")
        }
        api.fileProgressBlock = { progress in
            let total = Float(progress.totalUnitCount)
            let completed = Float(progress.completedUnitCount)
            let percentage = completed / total * 100
            print("上传进度: \(String(format:"%.2f",percentage)) %")
        }
        requestTask = api.uploadFile { [weak self] responseModel in
            if responseModel.isSuccess {
                self?.textView.backgroundColor = .init(patternImage: image)
            }
        }
    }
```

## **5.下载文文件示例**
    
```
func testDownloadFile() {
        //压缩包
        var  url = "http://i.gtimg.cn/qqshow/admindata/comdata/vipThemeNew_item_2135/2135_i_4_7_i_1.zip"
        //视频: (来源于: http://sp.jzsc.net)
        url = "http://down1.jzsc.net//sp/video/2019-06-22/d4fe4a94-0c21-4c99-ad35-2bdb23ab4de9.mp4"
        //图片
        url = "https://picsum.photos/375/667?random=1"
        
        let api = WXRequestApi(url, method: .get, parameters: nil)
        api.loadingSuperView = view
        
        api.fileProgressBlock = { progress in
            let total = Double(progress.totalUnitCount)
            let completed = Double(progress.completedUnitCount)
            let percentage = completed / total * 100.0
            print("下载进度: \(String(format:"%.2f",percentage)) %")
        }
        requestTask = api.downloadFile { [weak self] responseModel in
            if let rspData = responseModel.responseObject as? Data {
                if let image = UIImage(data: rspData) {
                    self?.textView.backgroundColor = .init(patternImage: image)
                }
                if var mimeType = responseModel.urlResponse?.mimeType {
                    mimeType = mimeType.replacingOccurrences(of: "/", with: ".")
                    let url = URL(fileURLWithPath: "/Users/xin610582/Desktop/" + mimeType, isDirectory: true)
                    try? rspData.write(to: url)
                }
            }
        }
    }
```


## Author

maowangxin_2013@163.com

## License

WXNetworkingSwift is available under the MIT license. See the LICENSE file for more info.


