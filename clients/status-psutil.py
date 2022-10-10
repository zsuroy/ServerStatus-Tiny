# -*- coding: utf-8 -*-
# Update by: https://github.com/zsuroy/ServerStatus-Tiny
# 依赖于psutil跨平台库：
# 支持Python版本：2.6 to 3.10
# 支持操作系统： Linux, Windows, OSX, Sun Solaris, FreeBSD, OpenBSD and NetBSD, both 32-bit and 64-bit architectures
# 特别支持：Termux、Raspberry

import socket
import time
import json
import psutil
import requests
from collections import deque

# socket mode: adapted for the orignal version
SERVER = "127.0.0.1"
PORT = 35601
USER = "USER"
PASSWORD = "USER_PASSWORD"
INTERVAL = 1  # 更新间隔，单位：秒

# backend mode: post the status data to the web
SERVER = "http://127.0.0.1/debug/stats/app.php"   # api_url: begin with "http(s)" or only ip address(domain)
PORT = 80                 # none
USER = "SUE-1"                # hostname
PASSWORD = "123"   # the verified password
INTERVAL = 5  # 更新间隔，单位：秒
SERVERINFO = {"name": "MAC", "type": "KVM", "host": USER, "location": "CN", "region": "CN", "os": "linux"}

# ===> either socket or backend mode shoule be saved.

# public settings following
CHECKSOURCE = 1 # 网络通讯正常测试源 [0: GFW, 1; CN]

def check_interface(net_name):
    net_name = net_name.strip()
    invalid_name = ['lo', 'tun', 'kube', 'docker', 'vmbr', 'br-', 'vnet', 'veth']
    return not any(name in net_name for name in invalid_name)


def get_uptime():
    return int(time.time() - psutil.boot_time())


def get_memory():
    mem = psutil.virtual_memory()
    swap = psutil.swap_memory()
    return int(mem.total / 1024.0), int(mem.used / 1024.0), int(swap.total / 1024.0), int(swap.used / 1024.0)


def get_hdd():
    valid_fs = ['ext4', 'ext3', 'ext2', 'reiserfs', 'jfs', 'btrfs', 'fuseblk', 'zfs', 'simfs', 'ntfs', 'fat32', 'exfat',
                'xfs']
    disks = dict()
    size = 0
    used = 0
    for disk in psutil.disk_partitions():
        if disk.device not in disks and disk.fstype.lower() in valid_fs:
            disks[disk.device] = disk.mountpoint
    for disk in disks.values():
        usage = psutil.disk_usage(disk)
        size += usage.total
        used += usage.used
    return int(size / 1024.0 / 1024.0), int(used / 1024.0 / 1024.0)


def get_load():
    try:
        return round(psutil.getloadavg()[0], 1)
    except Exception:
        return -1.0


def get_cpu():
    return psutil.cpu_percent(interval=INTERVAL)


class Network:
    def __init__(self):
        self.rx = deque(maxlen=10)
        self.tx = deque(maxlen=10)
        self._get_traffic()

    def _get_traffic(self):
        net_in = 0
        net_out = 0
        net = psutil.net_io_counters(pernic=True)
        for k, v in net.items():
            if check_interface(k):
                net_in += v[1]
                net_out += v[0]
        self.rx.append(net_in)
        self.tx.append(net_out)

    def get_speed(self):
        self._get_traffic()
        avg_rx = 0
        avg_tx = 0
        queue_len = len(self.rx)
        for x in range(queue_len - 1):
            avg_rx += self.rx[x + 1] - self.rx[x]
            avg_tx += self.tx[x + 1] - self.tx[x]
        avg_rx = int(avg_rx / queue_len / INTERVAL)
        avg_tx = int(avg_tx / queue_len / INTERVAL)
        return avg_rx, avg_tx

    def get_traffic(self):
        queue_len = len(self.rx)
        return self.rx[queue_len - 1], self.tx[queue_len - 1]


def get_network(ip_version, sourceID=0):
    host = [
        ["ipv4.google.com", "ipv6.google.com"],
        ["speed.neu.edu.cn", "speed.neu6.edu.cn"],
        ["test4.ustc.edu.cn", "test6.ustc.edu.cn"] #bug
    ]
    ip_type = 0 if ip_version == 4 else 1 # 确定ipV4/6
    HOST = host[sourceID][ip_type]

    try:
        s = socket.create_connection((HOST, 80), 2)
        s.close()
        return True
    except:
        pass
    return False


def post_backend(payload):
    if "http" not in SERVER:
        api = "http://" + str(SERVER) + "/app.php"
    else: api = SERVER
    api += "?mod=update&host=" + str(USER)+ "&psk=" + str(PASSWORD) + "&t="+ str(time.time())
    # for adapting python2 with 3: not beautiful
    z = SERVERINFO.copy()
    z.update(payload)
    payload = json.dumps(z)
    payload = {'param': payload}
    r = requests.post(api, data=payload, verify=False)
    print(r.text)

# not finished
def post_backend_socket(data):
    api = "/app.php?mod=update&host=" + str(USER)+ "&psk=" + str(PASSWORD) + "&t=12345678"
    # s= ssl.wrap_socket(socket.socket())
    s = socket.socket()
    s.connect((SERVER, PORT))
    s.send('POST ' + api + ' HTTP/1.1\r\n'.encode())
    s.send('Host: ' + str(SERVER) + '\r\n'.encode())
    s.send('Connection: keep-alive\r\n'.encode())
    s.send('Cache-Control: no-cache\r\n'.encode())
    s.send('Accept: text/html,application/json,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8\r\n'.encode())
    s.send('Upgrade-Insecure-Requests: 1\r\n'.encode())
    s.send('User-Agent: Mozilla/5.0 (Macintosh; ServerStatus) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36\r\n'.encode())
    s.send('Accept-Encoding: gzip, deflate, br\r\n'.encode())



if __name__ == '__main__':
    # is running in backenmode ?
    BACKENDMODE = True if 'SERVERINFO' in globals() or 'SERVERINFO' in locals() else False

    socket.setdefaulttimeout(30)
    while True:
        try:
            print("Connecting...")

            timer = 0
            check_ip = 4

            if not BACKENDMODE: # Socket mode
                s = socket.create_connection((SERVER, PORT))
                data = s.recv(1024).decode()
                if data.find("Authentication required") > -1:
                    s.send((USER + ':' + PASSWORD + '\n').encode("utf-8"))
                    data = s.recv(1024).decode()
                    if data.find("Authentication successful") < 0:
                        print(data)
                        raise socket.error
                else:
                    print(data)
                    raise socket.error

                if data.find('You are connecting via') < 0:
                    data = s.recv(1024).decode()
                    print(data)

                if data.find("IPv4") > -1:
                    check_ip = 4
                elif data.find("IPv6") > -1:
                    check_ip = 6
                else:
                    print(data)
                    raise socket.error

            traffic = Network()
            while True:
                CPU = get_cpu()
                NetRx, NetTx = traffic.get_speed()
                NET_IN, NET_OUT = traffic.get_traffic()
                Uptime = get_uptime()
                Load = get_load()
                MemoryTotal, MemoryUsed, SwapTotal, SwapUsed = get_memory()
                HDDTotal, HDDUsed = get_hdd()

                array = {}
                if not timer:
                    array['online' + str(check_ip)] = get_network(check_ip, CHECKSOURCE)
                    array['online' + str(4 if check_ip == '6' else '6')] = get_network(check_ip, CHECKSOURCE)
                    Online4 = array["online4"]
                    Online6 = array["online6"]
                    print("[check] network...")
                    timer = 150
                else:
                    timer -= 1 * INTERVAL

                array['online4'] = Online4
                array['online6'] = Online6
                array['uptime'] = Uptime
                array['load'] = Load
                array['memory_total'] = MemoryTotal
                array['memory_used'] = MemoryUsed
                array['swap_total'] = SwapTotal
                array['swap_used'] = SwapUsed
                array['hdd_total'] = HDDTotal
                array['hdd_used'] = HDDUsed
                array['cpu'] = CPU
                array['network_rx'] = NetRx
                array['network_tx'] = NetTx
                array['network_in'] = NET_IN
                array['network_out'] = NET_OUT

                print("[INFO]", array)
                if BACKENDMODE: s = post_backend(array)
                else: s.send(("update " + json.dumps(array) + "\n").encode("utf-8"))

        except KeyboardInterrupt:
            raise
        except socket.error:
            print("Disconnected...")
            # keep on trying after a disconnect
            if 's' in locals().keys():
                del s
            time.sleep(3)
        except Exception as e:
            print("Caught Exception:", e)
            if 's' in locals().keys():
                del s
            time.sleep(3)
