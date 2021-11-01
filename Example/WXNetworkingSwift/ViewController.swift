//
//  ViewController.swift
//  WXNetworkingSwift
//
//  Created by maowangxin on 10/08/2021.
//  Copyright (c) 2021 maowangxin. All rights reserved.
//

import UIKit
import WXNetworkingSwift
///判断文件类型
import MobileCoreServices

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    var requestTask: WXDataRequest? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        let url = "http://123.207.32.32:8000/home/multidata"
        let api = WXRequestApi(url, method: .get)
        api.timeOut = 40
        api.loadingSuperView = view
        api.autoCacheResponse = true
        api.successStatusMap = (key: "returnCode",  value: "SUCCESS")
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
//        api.testResponseJson =
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
