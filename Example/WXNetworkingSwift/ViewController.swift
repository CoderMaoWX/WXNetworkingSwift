//
//  ViewController.swift
//  WXNetworkingSwift
//
//  Created by maowangxin on 10/08/2021.
//  Copyright (c) 2021 maowangxin. All rights reserved.
//

import UIKit
import Alamofire
import WXNetworkingSwift
///判断文件类型
import MobileCoreServices

class ViewController: UIViewController {
    
    var requestTask: DataRequest? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        testRequestDelay()
    }
    
    //MARK: ----- 测试代码 -----
    
    func testRequestDelay() {
        let url = "https://httpbin.org/delay/5"
        let param: [String : Any] = ["name" : "张三"]
        let api = WXRequestApi(url, method: .get, parameters: param)
        api.timeOut = 40
        api.loadingSuperView = view
        api.startRequest { responseModel in
            print(" ==== 测试接口请求完成 ====== \(api)")
        }
    }
    
    func testBatchData() {
        let url0 = "http://123.207.32.32:8000/home/multidata"
        let api0 = WXRequestApi(url0, method: .get, parameters: nil)
        api0.successStatusMap = (key: "returnCode",  value: "SUCCESS")
        api0.autoCacheResponse = true
        
        
        let url1 = "https://httpbin.org/delay/5"
        let para1: [String : Any] = ["name" : "张三"]
        let api1 = WXRequestApi(url1, method: .get, parameters: para1)
        
        let api = WXBatchRequestApi(requestArray: [api0, api1], loadingTo: view)
        api.startRequest({ batchApi in
            print("批量请求回调", batchApi.responseDataArray)
        }, waitAllDone: false)
    }
    
    func testloadData() {
        let url = "http://app.u17.com/v3/appV3_3/ios/phone/comic/boutiqueListNew"
        let param: [String : Any] = ["sexType" : 1]

        let api = WXRequestApi(url, method: .get, parameters: param)
//        api.testResponseJson =
//"""
//        {"data":{"message":"成功","stateCode":1,"returnData":{"galleryItems":[],"comicLists":[{"comics":[{"subTitle":"少年 搞笑","short_description":"突破次元壁的漫画！","is_vip":4,"cornerInfo":"190","comicId":181616,"author_name":"壁水羽","cover":"https://cover-oss.u17i.com/2021/07/12647_1625125865_1za73F2a4fD1.sbig.jpg","description":"漫画角色发现自己生活在一个漫画的笼子里，于是奋起反抗作者，面对角色的不配合，作者不得已要不断更改题材，恐怖，魔幻，励志轮番上阵，主角们要一一面对，全力通关","name":"笼中人","tags":["少年","搞笑"]}],"comicType":6,"sortId":"86","newTitleIconUrl":"https://image.mylife.u17t.com/2017/07/10/1499657929_N7oo9pPOhaYH.png","argType":3,"argValue":8,"titleIconUrl":"https://image.mylife.u17t.com/2017/08/29/1503986106_7TY5gK000yjZ.png","itemTitle":"强力推荐作品","description":"更多","canedit":0,"argName":"topic"}],"textItems":[],"editTime":"0"}},"code":1}
//"""

        api.timeOut = 40
        api.loadingSuperView = view
        api.autoCacheResponse = false
        api.retryWhenFailTuple = (times: 3, delay: 1.0)
        api.successStatusMap = (key: "code", value: "1")
//        api.parseModelMap = (parseKey: "data.returnData.comicLists", modelType: ComicListModel.self)

        api.startRequest { responseModel in
            self.view.backgroundColor = .groupTableViewBackground
            if let rspData = responseModel.responseObject as? Data {
                if let image = UIImage(data: rspData) {
                    self.view.backgroundColor = .init(patternImage: image)
                }
            }
            print(" ==== 测试接口请求完成 ======")
        }
    }
    
    ///测试上传文件
    func testUploadFile() {
        let image = UIImage(named: "yaofan")!
        let imageData = UIImagePNGRepresentation(image)
        
//        let path = URL(fileURLWithPath: "/Users/luke/Desktop/video.mp4")
//        let imageData = Data.init(base64Encoded: path.absoluteString)
        
        let url = "http://10.8.31.5:8090/uploadImage  "
        let param = [
            "appName" : "TEST",
            "platform" : "iOS",
            "version" : "7.3.3",
        ]
        let api = WXRequestApi(url, method: .post, parameters: param)
        api.loadingSuperView = view
        api.retryWhenFailTuple = (times: 3, delay: 3.0)
        //api.successStatusMap = (key: "code", value: "1")
        
        api.uploadFileDataArr = [imageData!]
        api.fileProgressBlock = { progress in
            let total = Float(progress.totalUnitCount)
            let completed = Float(progress.completedUnitCount)
            let percentage = completed / total * 100
            print("上传进度: \(String(format:"%.2f",percentage)) %")
        }
        api.uploadFile { responseModel in
            if let rspData = responseModel.responseObject as? Data {
                if let image = UIImage(data: rspData) {
                    self.view.backgroundColor = .init(patternImage: image)
                }
            }
            print(" ==== 测试上传文件请求完成 ======")
        }
    }
    
    ///测试下载文件
    func testDownFile() {
        //图片
        let url = "https://picsum.photos/200/300?random=1"
        //压缩包
        //let url = "http://i.gtimg.cn/qqshow/admindata/comdata/vipThemeNew_item_2135/2135_i_4_7_i_1.zip"
        //视频
        //let url = "https://video.yinyuetai.com/d5f84f3e87c14db78bc9b99454e0710c.mp4"
        
        let api = WXRequestApi(url, method: .get, parameters: nil)
        api.loadingSuperView = view
        
        api.fileProgressBlock = { progress in
            let total = Float(progress.totalUnitCount)
            let completed = Float(progress.completedUnitCount)
            let percentage = completed / total * 100
            print("下载进度: \(String(format:"%.2f",percentage)) %")
        }
        api.downloadFile { responseModel in
            if let rspData = responseModel.responseObject as? Data {
                if let image = UIImage(data: rspData) {
                    self.view.backgroundColor = .init(patternImage: image)
                }
                if var mimeType = responseModel.urlResponse?.mimeType {
                    mimeType = mimeType.replacingOccurrences(of: "/", with: ".")
                    let url = URL(fileURLWithPath: "/Users/luke/Desktop/" + mimeType, isDirectory: true)
                    try? rspData.write(to: url)
                }
            }
            print(" ==== 测试下载文件请求完成 ======")
        }
    }
    
    ///https://hangge.com/blog/cache/detail_2216.html
    func getFileName() {
        //测试1
//        let mimeType1 = mimeType(pathExtension: "gif")
//        print(mimeType1)
        
        //测试2
//        let path = Bundle.main.path(forResource: "test1", ofType: "zip")!
        let url = URL(fileURLWithPath: "/Users/luke/Downloads/Jenkins 入门手册.pdf")
        let mimeType2 = mimeType(pathExtension: url.pathExtension)
        print("文件类型: \(mimeType2)")
    }
    
    //根据后缀获取对应的Mime-Type
    func mimeType(pathExtension: String) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           pathExtension as NSString,
                                                           nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?
                .takeRetainedValue() {
                return mimetype as String
            }
        }
        //文件资源类型如果不知道，传万能类型application/octet-stream，服务器会自动解析文件类
        return "application/octet-stream"
    }
    
}
