#!/bin/bash
set -e
# 安装基础工具
apt update
apt install util-linux python3-pip cmake -y
# 网络 ACL 测试工具
apt install curl netcat-openbsd -y
# 进程/内存压力工具
apt install stress -y
# HTTP 压力测试工具
apt install wrk hey -y
# 沙箱逃逸测试
pip3 install pwntools --break-system-packages
