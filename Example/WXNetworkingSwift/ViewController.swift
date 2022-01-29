//
//  ViewController.swift
//  WXNetworkingSwift
//
//  Created by maowangxin on 10/08/2021.
//  Copyright (c) 2021 maowangxin. All rights reserved.
//

import UIKit
import KakaJSON
import WXNetworkingSwift
///判断文件类型
import MobileCoreServices

class DKeywordListModel: Convertible {
    var acm: String? = nil
    var defaultKeyWord: String? = nil
    required init() {}
}

class DKeywordContextModel: Convertible {
    var currentTime: String? = nil
    var dataTime: String? = "20211117"
    required init() {}
}

class DKeywordModel: Convertible {
    var nextPage: String = "zhangSan"
    var isEnd: Int = 20
    var context: DKeywordContextModel? = nil
    var list: [DKeywordListModel]? = nil
    required init() {}
}

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    var requestTask: WXDataRequest? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //测试设置全局: 请求状态/解析模型
        WXRequestConfig.shared.successStatusMap = (key: "returnCode",  value: "SUCCESS")
        WXRequestConfig.shared.uploadRequestLogTuple = (url: "http://10.8.41.162:8090/pullLogcat", catchTag: "mwx345")
        WXRequestConfig.shared.messageTipKeyAndFailInfo = (tipKey: "returnCode", defaultTip: "我的默认错误页面提示文案")
        WXRequestConfig.shared.forbidProxyCaught = true
        WXRequestConfig.shared.urlResponseLogTuple = (printf: true, hostTitle: "开发环境")
        WXRequestConfig.shared.requestHUDCalss = WXLoadingHUD.self
    }
    
    ///感谢你的点赞
    @IBAction func giveStarsAction(_ sender: UIBarButtonItem) {
        let url = URL(string: "https://github.com/CoderMaoWX/WXNetworkingSwift")
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
    
    @IBAction func requestButtonAction(_ sender: UIBarButtonItem) {
        testRequest()
    }
    
    //MARK: ----- 测试单个请求 -----
    func testRequest() {
//        let url = "https://httpbin.org/delay/5"
        let url = "http://123.207.32.32:8000/home/multidata"
        let api = WXRequestApi(url, method: .get)
        api.timeOut = 40
        api.loadingSuperView = view
        //api.autoCacheResponse = true
        api.successStatusMap = (key: "returnCode",  value: "SUCCESS")
        api.parseModelMap = (parseKey: "data.dKeyword", modelType: DKeywordModel.self)
        requestTask = api.startRequest { [weak self] responseModel in
            self?.textView.text = responseModel.responseDict?.description
        }
    }
    
    
    //MARK: ----- 测试批量请求 -----
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
    
    
    //MARK: ----- 测试Json请求解析模型 -----
    func testParseModel() {
        let url = "http://app.u17.com/v3/appV3_3/ios/phone/comic/boutiqueListNew"
        let param: [String : Any] = ["sexType" : 1]

        let api = WXRequestApi(url, method: .get, parameters: param)
//        api.debugJsonResponse = "http://10.8.41.162:8090/app/activity/page/detail/92546"  //http(s) URL
//        api.debugJsonResponse = "/Users/xin610582/Desktop/test.json"                      //Desktop json file
//        api.debugJsonResponse = "test.json"                                               //Bundle json file
//        api.debugJsonResponse = ["code" : "1", "data" : ["message" : "测试字典"]]           //Dictionary Object
        api.debugJsonResponse = "{\"code\":\"1\",\"data\":{\"message\":\"测试json\"}}"     //Json String

        api.timeOut = 40
        api.loadingSuperView = view
        api.autoCacheResponse = false
        api.retryWhenFailTuple = (times: 3, delay: 1.0)
        api.successStatusMap = (key: "code", value: "1")
        // api.parseModelMap = (parseKey: "data.returnData.comicLists", modelType: ComicListModel.self)

        requestTask = api.startRequest { [weak self] responseModel in
            self?.textView.text = responseModel.responseDict?.description
        }
    }
    
    
    //MARK: ----- 测试上传文件 -----
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
    
    
    //MARK: ----- 测试下载文文件 -----
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
        api.downloadFile { [weak self] responseModel in
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
    

}
