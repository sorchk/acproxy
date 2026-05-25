# ACP Proxy - 实现计划

## 目标

构建两个跨平台 (linux/amd64, linux/arm64) 的执行文件：
1. `acproxy` - 宿主机端 ACP 代理
2. `socket_bridge` - Docker 容器内 Socket ↔ stdio 桥接

## 项目结构

```
/datadisk/test/acproxy/
├── cmd/
│   ├── acproxy/
│   │   └── main.go           # acproxy 主程序入口
│   └── socket_bridge/
│       └── main.go           # socket_bridge 主程序入口
├── internal/
│   ├── config/
│   │   └── config.go         # YAML 配置解析
│   ├── proxy/
│   │   └── proxy.go          # ACP 帧透传 + 权限自动批准
│   └── socket/
│       └── client.go         # Unix Socket 客户端
├── container/
│   ├── Dockerfile            # 容器镜像构建
├── config.yaml.example       # 配置示例
├── Makefile                  # 交叉编译脚本
└── README.md                 # 使用说明
```

## 实现步骤

### Step 1: 项目初始化
- 创建目录结构
- 编写 Makefile (交叉编译 targets)
- 创建 config.yaml.example

### Step 2: 配置解析 (internal/config/config.go)
- 定义 Config 结构体
- 从 `~/.acproxy/config.yaml` 读取配置
- 支持 agent 名称 → (container, socket) 映射

### Step 3: Unix Socket 客户端 (internal/socket/client.go)
- 连接到指定 Unix Socket
- 双向数据传输 (stdio ↔ socket)
- 连接失败处理

### Step 4: ACP 帧透传 (internal/proxy/proxy.go)
- 从 stdin 读取 JSON-RPC 帧
- 发送到 Unix Socket
- 从 Unix Socket 接收响应
- 输出到 stdout
- **拦截并自动批准 `session/request_permission`**

### Step 5: acproxy 主程序 (cmd/acproxy/main.go)
- 解析 `--agent` 命令行参数
- 加载配置
- 启动 socket 客户端
- 运行帧透传

### Step 6: socket_bridge 主程序 (cmd/socket_bridge/main.go)
- 解析 `--socket` 命令行参数
- 在 Unix Socket 上监听
- 收到连接后 fork/exec 真实 agent
- 纯透传桥接数据流（不解析业务逻辑）
- 处理进程退出

### Step 7: Dockerfile
- 基于 ubuntu:22.04
- 复制 socket_bridge
- 暴露 /sock volume

### Step 8: 交叉编译验证
```bash
make all
# 生成:
# bin/acproxy-linux-amd64
# bin/acproxy-linux-arm64
# bin/socket_bridge-linux-amd64
# bin/socket_bridge-linux-arm64
```

## 关键设计决策

1. **权限自动批准位置**: 在 acproxy 端拦截，不转发 `session/request_permission` 到容器
2. **Socket 消息格式**: 每条消息以 `\n` 分隔的原始 JSON-RPC 帧
3. **错误处理**: Socket 断开时优雅退出，错误信息到 stderr

## 验证标准

- [ ] amd64 和 arm64 都能成功编译
- [ ] acproxy 能连接 socket_bridge
- [ ] ACP 协议帧能正确透传
- [ ] session/request_permission 被正确拦截并自动批准
- [ ] 容器能正常启动 socket_bridge
