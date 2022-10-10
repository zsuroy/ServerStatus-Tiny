<!--suppress HtmlDeprecatedAttribute -->

<div align="center">
  <p>
    <img alt="logo" src="https://ghproxy.com/github.com/zsuroy/ServerStatus-Tiny/blob/main/logo.svg"/>
  </p>

  <h1>ServerStatus-Tiny</h1>
  <p>多服务器一站式监控平台</p>

  <p>
    <a href="https://suroy.cn"><img alt="SUROY(BLOG)" src="https://img.shields.io/website?down_message=FLOWER&label=SUROY&up_color=ff69b4&up_message=DREAM&logo=micro:bit&url=https%3A%2F%2Fsuroy.cn"></a>
    <a href="https://github.com/zsuroy"><img alt="Suroy" src="https://img.shields.io/github/languages/top/zsuroy/serverstatus-tiny?style=flat-square"/></a>
    <a href="https://github.com/zsuroy"><img alt="Suroy" src="https://img.shields.io/github/languages/count/zsuroy/serverstatus-tiny?style=flat"/></a>
    <a href="https://github.com/zsuroy"><img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/zsuroy/serverstatus-tiny"></a>
    <img alt="GitHub" src="https://img.shields.io/github/license/zsuroy/serverstatus-tiny">
    <a href="https://github.com/zsuroy"><img alt="GitHub AutoJs6 repository" src="https://img.shields.io/badge/Python->= 2.7-67a91b"/></a>
  </p>
</div>




## 🗒️简介说明

******

> 
> ServerStatus-Tiny
> 
> 多服务器探针监控平台便携版
>
> 2022.10.1

1. 基于 ServerStatus-Hotaru 开发
2. `开发` 后端为 `PHP` 接口，以实现 `Windows/Linux` **均可架设服务端**
3. `小改` UI界面-VUE，优化卡片显示
4. `增加` 各操作系统旗帜：含树莓派(`Raspberry`)、`Termux`、`Linux` 等
5. `增加` 双栈 `IPV6/IPV4` 监控支持、增加国内服务器在线监控支持
6. `增加` 单个服务器监控IP地址数据、在线时间字段
7. `适配` `Termux`，能够监控 termux，支持androd7+，无root/root均可
8. `修复` 跨平台支持，已测试: Mac、Windows 2012、Ubuntu、Termux(Android 10、Android 6)、Raspberry 2B+
9. `兼容` 兼容原版 `ServerStatus`、`ServerStatus-Hotaru`、`ServerStatus-Tokyo`
10. **总结**：无需docker、支持跨平台、支持Termux

_演示图_
![ServerStatus_Tiny](https://ghproxy.com/github.com/zsuroy/ServerStatus-Tiny/blob/main/ServerStatus-Tiny.png)


******

## 🤡前言
二开这个项目主要是由于原项目需要 `docker` 部署服务端，要跑一个 caddy 的服务端；
1. 无奈于架设比较繁琐，其实主要原因是我需要在 Windowserver 2012 云服务器不支持虚拟化，无法跑不了 docker 也就安装不了服务端；
2. 之后尝试了一下在树莓派上面跑，估计是硬件太久远了也跑不起来，socket 一直重连！！！
3. 我需要监控一下几个 `Termux` 服务，试了一下都跑不了，各种报错
4. 于是，重写了～😅
---
ps: 写 `shell` 脚本时............一言难尽


## 🎲使用说明
> 主题: 基于 Vue 3 和 Semantic UI ServerStatus  
> 监控: 基于 ServerStatus        服务器后端: PHP
>
- 所有客户端/服务端均做了兼容处理
- 理论上兼容原版 `ServerStatus`、`ServerStatus-Hotaru`、`ServerStatus-Tokyo`
- 若只喜欢本项目`WEB`界面：可以只替换本项目 `WEB` 覆盖目标WEB目录，并配置好`PHP`环境即可
- 若只需要兼容 `Termux` 可以只使用 `client.sh`(无root推荐)、`status-psutil.py`(有root推荐)
- 欢迎fork、PR
- **[注]!!!** 客户端中需要修改配置，`socket模式/后端模式` _二选一！！！_为了兼容原项目预留的
- [已测试平台]
  - 均以 WindowsServer2012 作为`PHP`**服务端**，运行在本项目 `Backend` 模式下
  - `MacOS` Python3.10 psutil==5.5 客户端 `status-psutil.py` 正常✅
  - `Windows` Python3.8 psutil==2.2.1 客户端 `status-psutil.py` 正常✅
  - `Raspberry 2B+` Python3.8 psutil==2.2.1 客户端 `status-psutil.py` 正常✅
  - `Termux - Android 6 rooted` Python3.7 psutil==2.2.1 客户端 `status-psutil.py` 正常✅
  - `Termux - Android 10 rooted` Python3.10.11 psutil==2.2.1 客户端 `status-psutil.py` 正常✅
  - `Termux - Android 10 No root` 客户端 `client.sh` 正常✳️ (网速/流量读取不到)
  
### 一键脚本
```shell
# 服务端 | 手动指派网站目录 php >= 5
git clone https://github.com/zsuroy/ServerStatus-Tiny
cd WEB

# 跨平台客户端 | 若 psutil 报错 > 装2.2.1
git clone https://github.com/zsuroy/ServerStatus-Tiny
cd clients
pip install -r requirements.txt
python3 status-psutil.py

# Linux 可选客户端 | 特指 termux(无root推荐)
git clone https://github.com/zsuroy/ServerStatus-Tiny
cd clients
bash client.sh

```

### 配置修改

> 只介绍本项目后端模式的修改，socket模式的配置，请参考底部相关项目链接
> 

#### 服务端
>  接口 `app.php`; 前台 `config.js`
```php
define("FILE_NAME", "./json/stats.json"); //文件名
define("PSK", "123"); //PASSWORD
```

#### 客户端
```text
# [Client-psutil.py]

# backend mode: post the status data to the web
SERVER = "http://127.0.0.1/debug/stats/app.php"   # 服务端api接口地址：可以直接域名或ip或完整路径
PORT = 80                 # 后端模式端口无用
USER = "SUE-1"                # 主机名：标示作用
PASSWORD = "123"   # 随机生成个复杂的密码与服务端保持一致
INTERVAL = 5  # 更新间隔，单位：秒
SERVERINFO = {"name": "MAC", "type": "KVM", "host": USER, "location": "CN", "region": "CN"} # 公共信息

# ===> either socket or backend mode shoule be saved.

# public settings following
CHECKSOURCE = 1 # 网络通讯正常测试源 [0: GFW, 1; CN]


# [client.sh]

SERVER="http://192.168.1.4/debug/stats/" # api_url: begin with "http(s)" or only ip address(domain)
PORT=35601  # 端口无用
USER="SUROY-DEMO" # hostname
PASSWORD="123" # the verified password
INTERVAL=1 # Update interval

BACKENDMODE=0 # 后端模式: 0启动
SOURCEID=1  # 网络通讯正常测试源 [0: GFW, 1; CN]
SERVERINFO="\"name\":\"Nova4e\",\"type\":\"termux\",\"host\":\"${USER}\",\"location\":\"CN\",\"region\":\"termux\",\"custom\":\"\","

```

#### 😇数据模版
> 开发了包括但不限于以下模版
> 
```json
{ "name": "显示名","type":"架构","host":"主机名-唯一标示","location":"地区","region":"地区-旗帜","custom":"用户自定义显示内容","online4":"IPV4状态","online6":"IPV4状态","uptime":"服务器在线时间","load":"服务器负载","memory_total":"总内存","memory_used":"已用内存","swap_total":"swap","swap_used":750628,"hdd_total":"硬盘大小","hdd_used":25600,"cpu":0,"network_rx":3020,"network_tx":1020, "network_in": 40924739, "network_out": 14312368,"updated":"上次更新时间戳","ip":"IP地址"}

{ "name": "Linux","type":"Arm","host":"SUROY","location":"CN","region":"linux","os":"archlinux","custom":"","online4":true,"online6":false,"uptime":"7d 12:36","load":1.25,"memory_total":9768472,"memory_used":1249760,"swap_total":2393756,"swap_used":750628,"hdd_total":213780,"hdd_used":25600,"cpu":0,"network_rx":3020,"network_tx":1020, "network_in": 40924739, "network_out": 14312368,"updated":"10-10 12:30:40","ip":"192.168.1.4"}
```

特殊旗帜：树莓派`raspberry`、Termux`termux`、Linux`linux`、海盗旗`pirate`、彩虹旗`rainbow`、`trans`

替换旗帜即替换 `region` 或 `os` 属性内容，更多旗帜参考 `V1.0.2` 更新

- 运行有问题请查看 [🏄🏻注意事项](#🏄🏻注意事项)
- 二次开发请查看 [🍧开发说明](#🍧开发说明)

******

## 🕹计划任务

> Termux 开机自启任务

```shell
#!/data/data/com.termux/files/usr/bin/sh
screen -wipe
screen -dmS status python3 /data/data/com.termux/files/home/ServerStatus/status-psutil.py
```


## 🏄🏻注意事项

### device

> 总结  
> [Termux] 无root推荐 `client.sh`、有root推荐 `status-psutil.py`
> 
> 其余设备均用 `status-psutil.py`
> 

1. Termux 
    + proot
    + psutil 2.2.1 ```pip3 install psutil==2.2.1```
    + python2.7/3.8/3.10
    + **Need root!!!**
    + error when having no root (Android 7+ no permission view /proc)
   https://github.com/giampaolo/psutil/issues/384
    ```text
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
      File "/data/data/com.termux/files/usr/lib/python3.10/site-packages/psutil/__init__.py", line 90, in <module>
        import psutil._pslinux as _psplatform
      File "/data/data/com.termux/files/usr/lib/python3.10/site-packages/psutil/_pslinux.py", line 123, in <module>
        scputimes = namedtuple('scputimes', _get_cputimes_fields())
      File "/data/data/com.termux/files/usr/lib/python3.10/site-packages/psutil/_pslinux.py", line 107, in _get_cputimes_fields
        with open('/proc/stat', 'rb') as f:
    PermissionError: [Errno 13] Permission denied: '/proc/stat'
    ```


******



## 🙈目前存在的问题

- Termux: `client.sh` 无法获取流量/网速数据
- 新发现问题请提交ISSUE，我会尽快跟进解决

******



## 🍧开发说明

******

> 普通用户请直接忽略
> 
> 仅仅记录个人开发过程的BUG苦逼历程

+ `[开发设备]`

  - `机型`: Mac Os
  - `版本`: Python3.9  




## 👑更新记录

******

- 历史版本更新记录可前往[RELEASES 页面](https://github.com/zsuroy/ServerStatus-Tiny/realease) 查看

### V1.0.2 22.10.8-10

- WEB: 新增离线检测判定服务 `app.php`
- 新增服务器ip、在线时间显示
- 旗帜新增 `ubuntu`、`debian`、`windows`、`docker`、`fedora`、`centos`、`suselinux`、`archlinux`、`nas`、`router`、`android`、`mac`、`ios`
- 双旗帜卡片显示模式: 左侧地区、右侧系统

## ☄️致谢开源

******
* ServerStatus-Hotaru: https://github.com/cokemine/ServerStatus-Hotaru MIT License
* ServerStatus：https://github.com/BotoX/ServerStatus WTFPL License
* ServerStatus-Toyo：https://github.com/ToyoDAdoubiBackup/ServerStatus-Toyo MIT License
* 国内IPV6资源检测：东北大学测速站、test-ipv6.com
* 图标、旗帜: iconfont


## 🌈打赏 (Tip)

******

<details><summary>查看详情 (Click to show details)</summary><br>
<div align="center">
To tip online, scan the QR code below <br>
扫描对应二维码可打赏 <br><br>
I believe I could make it better with your support :) <br>
感谢每一份支持和鼓励 <br><br>

<a href="https://suroy.cn/usr/themes/Sunshine/images/donate/alipay.png"><img alt="Alipay sponsor" src="https://suroy.cn/usr/themes/Sunshine/images/donate/alipay.png" height="224"/></a>
<a href="https://suroy.cn/usr/themes/Sunshine/images/donate/wechat.png"><img alt="WeChat sponsor" src="https://suroy.cn/usr/themes/Sunshine/images/donate/wechat.png" height="224"/></a>
</div>
</details>


## 👨🏻‍💻关于作者

******

[@Suroy](https://suroy.cn)




