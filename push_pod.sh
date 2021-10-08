#!/bin/sh

#自动发布WXNetwork网络库shell脚本

#拉取最新
git pull

#检索出 spec.version  =''
VersionText=`grep -E 'spec.version.*=' WXNetworking.podspec`

#获取版本号 '2.0'
VersionNumber=${VersionText#*=}

#去除两边的引号 $VersionNumber | sed 's/^.\(.*\).$/\1/'=

#对版本号进行自增
NewVersionNumber=$(echo $VersionNumber | sed 's/^.\(.*\).$/\1/' | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}')
echo ${NewVersionNumber}

ReplaceVersion="'$NewVersionNumber'"

#获取到spec.version所在的行
LineNumber=`grep -nE 'spec.version.*=' WXNetworking.podspec | cut -d : -f1`

#替换里面的版本号数字
sed -i "" "${LineNumber}s/${VersionNumber}/${ReplaceVersion}/g" WXNetworking.podspec

echo "\033[41;36m 当前版本号为: ${VersionNumber}, 新制作的版本号为: ${ReplaceVersion} \033[0m "


#提交所有修改
git add .
git commit -am "打 tag: ${NewVersionNumber}"

#提交所有修改推到Gitlab
git push


#删除本地相同的版本号(拿最新Tag的代码)
git tag -d ${NewVersionNumber}

#打Tag推上远程pod
git tag ${NewVersionNumber}
git push --tags

# 制作并推到远程库
pod trunk push WXNetworking.podspec --allow-warnings --verbose --use-libraries

if [ $? == 0 ] ; then
    echo "\033[41;36m 第三方库 WXNetworking Pod库制作成功, 请在项目中使用: pod 'WXNetworking', '~>${NewVersionNumber}' 导入 \033[0m "
    
    NewVersionURL="https://cocoapods.org/pods/WXNetworking"
    echo "最新版本号: $NewVersionURL"
    open $NewVersionURL
    
else
    echo "\033[41;36m 第三方库 WXNetworking Pod库制作失败, 请查看终端打印日志排查原因 \033[0m "
fi
