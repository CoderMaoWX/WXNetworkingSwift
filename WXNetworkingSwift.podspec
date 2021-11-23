Pod::Spec.new do |s|
  s.name             = 'WXNetworkingSwift'
  s.version          ='0.2.4'
  s.summary          = 'iOS基于Alamofire封装的可定制多功能网络请求框架'

  s.description      = <<-DESC
  封装一套网络请求,自动处理是否缓存, 请求失败多多次重试, 上传接口日志, 极简上传下载文件监听, 约定全局请求成功keyPath模型映射,约定全局请求的提示tipKey,请求遇到相应Code时触发通知,网络请求过程多链路回调管理,格式化打印网络日志, 批量请求, 调试响应json等使用功能 ...
                       DESC

  s.homepage         = 'https://github.com/CoderMaoWX/WXNetworkingSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'maowangxin' => 'maowangxin_2013@163.com' }
  s.source           = { :git => 'https://github.com/CoderMaoWX/WXNetworkingSwift.git', :tag => s.version.to_s }
   s.social_media_url = 'https://www.jianshu.com/u/c4ac9f9adf58'

  s.requires_arc = true
  s.swift_versions = ['5.0']
  s.frameworks  = "Foundation"
  s.ios.deployment_target = '10.0'
  s.source_files = 'WXNetworkingSwift/*.swift'

  s.dependency 'Alamofire'
  s.dependency 'KakaJSON'
  
end
