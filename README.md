# WXNetworkingSwift

[![CI Status](https://img.shields.io/travis/maowangxin/WXNetworkingSwift.svg?style=flat)](https://travis-ci.org/maowangxin/WXNetworkingSwift)
[![Version](https://img.shields.io/cocoapods/v/WXNetworkingSwift.svg?style=flat)](https://cocoapods.org/pods/WXNetworkingSwift)
[![License](https://img.shields.io/cocoapods/l/WXNetworkingSwift.svg?style=flat)](https://cocoapods.org/pods/WXNetworkingSwift)
[![Platform](https://img.shields.io/cocoapods/p/WXNetworkingSwift.svg?style=flat)](https://cocoapods.org/pods/WXNetworkingSwift)

## 功能列表:
 
1、封装一套网络请求;

2、自动处理是否缓存;

3、请求失败多多次重试;

4、上传接口日志;

5、极简上传下载文件监听;

6、约定全局请求成功keyPath模型映射;

7、约定全局请求的提示tipKey;

8、请求遇到相应Code时触发通知;

9、网络请求过程多链路回调管理;

10、格式化打印网络日志;

11、批量请求;

12、调试响应json等使用功能;

 . . . . . .

## Requirements
> iOS, swift 5.0

## Installation

WXNetworkingSwift is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WXNetworkingSwift'
```

## Usage

1.单个请求
    
```
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
```
2.批量请求
    
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
3.Json请求解析模型
    
```
func testParseModel() {
        let url = "http://app.u17.com/v3/appV3_3/ios/phone/comic/boutiqueListNew"
        let param: [String : Any] = ["sexType" : 1]

        let api = WXRequestApi(url, method: .get, parameters: param)
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
4.上传文件
    
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
5.下载文文件
    
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


