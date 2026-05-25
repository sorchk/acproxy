# ACP Proxy - 设计规格书

## 概述

ACP Proxy 是一个透明的 ACP (Agent Communication Protocol) 代理工具。它充当 ACP agent 角色，接收来自任意 ACP 兼容程序的调用请求，通过 Unix Domain Socket 转发给运行在 Docker 容器中的真实 Agent CLI，并将响应原样传回。

**核心原则**：完全透明转发 ACP 协议帧，不解析业务逻辑。

## 架构

```
┌──────────────────────────────────────────────────────────────┐
│                         宿主机                               │
│                                                              │
│  ┌────────────────┐    stdio     ┌──────────────────────┐  │
│  │  ACP 兼容调用者  │◄────────────►│   acproxy (代理)      │  │
│  │  (任意程序)      │              │   - 读取配置          │  │
│  └────────────────┘              │   - 连接 Unix Socket   │  │
│                                  │   - 透传 ACP 帧        │  │
│                                  └──────────┬───────────┘  │
│                                             │              │
│  ~/.acproxy/config.yaml                     │ Unix Socket  │
│  /tmp/acproxy/*.sock                        │              │
└────────────────────────────────────────────┼──────────────┘
                                             │
                                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                        Docker 容器                                │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  socket_bridge                                              │   │
│  │  - 监听 Unix Socket                                         │   │
│  │  - fork/exec 真实 agent CLI                                 │   │
│  │  - 桥接 Socket ↔ stdio 数据流                              │   │
│  │  - 自动批准所有 session/request_permission                   │   │
│  └───────────────────────────┬───────────────────────────────┘   │
│                              │ stdio                             │
│                              ▼                                    │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  真实的 Agent CLI (pi / opencode / kimi / hermes / kiro)   │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

## 组件设计

### 1. acproxy (宿主机端)

**职责**：
- 读取配置文件 `~/.acproxy/config.yaml`
- 通过 Unix Socket 连接到容器内的 socket_bridge
- 透传所有 ACP 协议帧（stdin → socket, socket → stdout）
- 自动批准所有 `session/request_permission` 请求

**命令行接口**：
```bash
acproxy --agent=<name>
# 例如: acproxy --agent=pi
#      acproxy --agent=opencode
```

**配置格式** (`~/.acproxy/config.yaml`)：
```yaml
pi:
  container: "agent-pi"
  socket: "/tmp/acproxy/pi.sock"

opencode:
  container: "agent-opencode"
  socket: "/tmp/acproxy/opencode.sock"

kimi:
  container: "agent-kimi"
  socket: "/tmp/acproxy/kimi.sock"

hermes:
  container: "agent-hermes"
  socket: "/tmp/acproxy/hermes.sock"

kiro:
  container: "agent-kiro"
  socket: "/tmp/acproxy/kiro.sock"
```

### 2. socket_bridge (容器内)

**职责**：
- 在配置的 socket 路径上监听 Unix Socket 连接
- 收到连接后，fork/exec 对应的真实 Agent CLI
- 桥接 Socket ↔ stdio 双向数据流（纯透传，不解析业务逻辑）

**启动方式**：
```bash
socket_bridge --socket=/sock/pi.sock -- bin/pi acp
socket_bridge --socket=/sock/opencode.sock -- opencode run --format json
```

### 3. 容器镜像

**构建产物**：`acproxy/container/Dockerfile`

```dockerfile
FROM ubuntu:22.04

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 复制 socket_bridge
COPY socket_bridge /usr/local/bin/

# socket 挂载点
VOLUME ["/sock"]

ENTRYPOINT ["socket_bridge"]
```

## ACP 协议透传

### 透传规则

| 消息类型 | 处理方式 |
|----------|----------|
| JSON-RPC Request (`{"id":..., "method":...}`) | 透传到容器 |
| JSON-RPC Response (`{"id":..., "result":...}`) | 透传到调用者 |
| JSON-RPC Notification (`{"method":...}` 无 id) | 透传到调用者 |
| `session/request_permission` | 本地自动批准，不转发到容器 |

### 会话生命周期

```
1. initialize
   调用者 → acproxy → socket_bridge → 真实 agent
   acproxy 记录协议版本和能力

2. session/new 或 session/resume
   调用者 → acproxy → socket_bridge → 真实 agent
   acproxy 透传请求，获取 sessionId

3. session/set_model (可选)
   调用者 → acproxy → socket_bridge → 真实 agent

4. session/prompt
   调用者 → acproxy → socket_bridge → 真实 agent
   真实 agent 产生多个 session/update 通知
   acproxy 将通知原样传回调用者

5. session/request_permission
   真实 agent → acproxy
   acproxy 本地自动批准，回复 approve_for_session
   (不转发到容器)
```

### Socket 消息格式

Socket 上传输的是完整的 JSON-RPC 帧，每条消息以换行符 `\n` 分隔：

```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{...}}
{"jsonrpc":"2.0","method":"session/update","params":{...}}
{"jsonrpc":"2.0","id":2,"method":"session/new","params":{...}}
```

## 文件结构

```
/datadisk/test/acproxy/
├── cmd/
│   └── acproxy/
│       └── main.go              # acproxy 主程序
│   └── socket_bridge/
│       └── main.go              # socket_bridge 主程序入口
├── internal/
│   ├── config/
│   │   └── config.go            # YAML 配置解析
│   ├── proxy/
│   │   └── proxy.go             # ACP 帧透传 + 权限自动批准
│   └── socket/
│       └── client.go            # Unix Socket 客户端
├── container/
│   ├── Dockerfile               # 容器镜像构建
├── config.yaml.example          # 配置示例
├── Makefile                     # 构建脚本
└── README.md                    # 使用说明
```

## 构建

### acproxy (宿主机端)

```bash
cd /datadisk/test/acproxy
make build-acproxy
# 输出: bin/acproxy
```

### socket_bridge + 容器镜像

```bash
make build-container
# 构建 socket_bridge 并打包到 Docker 镜像
```

## 使用方式

### 1. 宿主机配置

```bash
mkdir -p ~/.acproxy
cp config.yaml.example ~/.acproxy/config.yaml
# 编辑 config.yaml 指定容器名和 socket 路径

# 添加别名 (在 ~/.bashrc 或 ~/.zshrc)
echo 'alias pi=/path/to/acproxy --agent=pi' >> ~/.bashrc
echo 'alias opencode=/path/to/acproxy --agent=opencode' >> ~/.bashrc
source ~/.bashrc
```

### 2. 启动容器

```bash
docker run -d \
  --name agent-pi \
-v /datadisk/pi:/root \
 sorc/acproxy socket_bridge --socket=/root/.pi/pi.sock -- pi acp

docker run -it \
--user=root \
--rm --name agent-pi \
-v /datadisk/pi:/root \
 sorc/acproxy socket_bridge --socket=/root/.pi/pi.sock -- pi acp
```
### 3. 调用

```bash
# 通过别名调用
pi "帮我写一个 hello world"

# 或者直接使用 acproxy
acproxy --agent=pi -- "帮我写一个 hello world"
```

## 错误处理

| 场景 | 处理方式 |
|------|----------|
| 配置文件不存在 | 退出并报错 |
| Socket 连接失败 | 退出并报错 "connection refused" |
| 容器内 agent 崩溃 | 关闭 socket 连接，acproxy 退出 |
| 无效的 ACP 消息 | 透传，让容器内的 agent 处理 |

## 安全考虑

- Socket 文件使用 `0777` 权限，允许所有用户访问
- 容器内 agent 运行在隔离环境
- 不在日志中输出敏感的 prompt 内容
