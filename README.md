# ACP Proxy

透明 ACP (Agent Communication Protocol) 代理，将 ACP 调用转发到 Docker 容器中运行的真实 Agent CLI。

## 组件

| 文件 | 环境 | 说明 |
|------|------|------|
| `acproxy` | 宿主机 | ACP agent 代理，透传协议到容器 |
| `socket_bridge` | Docker 容器 | Socket ↔ stdio 桥接，fork 真实 agent |

## 构建

```bash
make all
```

生成:
- `bin/acproxy-linux-amd64`
- `bin/acproxy-linux-arm64`
- `bin/socket_bridge-linux-amd64`
- `bin/socket_bridge-linux-arm64`

## 使用

### 1. 宿主机配置

```bash
mkdir -p ~/.acproxy
cp config.yaml.example ~/.acproxy/config.yaml
# 编辑 config.yaml 指定容器名和 socket 路径
```

### 2. 添加别名

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加
alias pi='/path/to/acproxy --agent=pi'
alias opencode='/path/to/acproxy --agent=opencode'
```

### 3. 启动容器

```bash
docker run -d \
  --name agent-pi \
-v /datadisk/pi:/root \
  sorc/acproxy:pi \
  socket_bridge --socket=/root/.pi/pi.sock -- pi acp


docker run -it \
--user=root \
--rm --name agent-pi \
-v /datadisk/pi:/root \
 sorc/acproxy-pi \
 socket_bridge --socket=/root/.pi/pi.sock -- pi acp
```

### 4. 调用

```bash
pi "帮我写一个 hello world"
```

## 工作原理

```
宿主机: acproxy <--stdin/stdout--> 任意ACP调用者
                |
                | Unix Socket (/tmp/acproxy/pi.sock)
                ▼
容器内:   socket_bridge <--stdio--> 真实agent (pi/opencode/kimi/hermes/kiro)
```
