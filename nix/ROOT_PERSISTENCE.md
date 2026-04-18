# /root 目录持久化配置说明

## 概述

为确保 QwenPaw 容器重启后用户数据和 Nix 包管理器状态保持,已配置 `/root` 目录的持久化。

## 配置内容

### Docker Volume

在 `docker-compose.yml` 中添加了新的 Volume:

```yaml
volumes:
  qwenpaw-root:
    name: qwenpaw-root

services:
  qwenpaw:
    volumes:
      - qwenpaw-root:/root
```

### 持久化的内容

挂载 `/root` 目录后,以下内容将被持久化:

1. **Nix Profile** (`/root/.nix-profile/`)
   - 已安装的 Nix 软件包
   - 软件包符号链接
   - 包管理配置

2. **Nix 配置** (`/root/.nix-defexpr/`)
   - Channel 定义
   - 包表达式

3. **Nix Channel** (`/root/.nix-channels/`)
   - Channel 元数据
   - 包索引

4. **用户配置** (`/root/.*`)
   - `.bashrc` - Shell 配置
   - `.profile` - 环境配置
   - 其他点文件

5. **用户数据** (`/root/*`)
   - 下载的文件
   - 临时工作文件
   - 自定义脚本

## 验证方法

### 1. 检查 Volume 状态

```bash
# 查看 Volume 信息
docker volume inspect qwenpaw-root

# 查看挂载点
docker inspect qwenpaw --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
```

### 2. 测试持久化

```bash
# 创建测试文件
docker exec qwenpaw bash -c "echo 'test' > /root/test.txt"

# 重启容器
docker compose restart

# 验证文件存在
docker exec qwenpaw cat /root/test.txt
```

### 3. 检查 Nix 状态

```bash
# 查看 Nix profile
docker exec qwenpaw ls -la /root/.nix-profile/

# 查看已安装的包
docker exec qwenpaw ls /root/.nix-profile/bin/

# 检查 channel
docker exec qwenpaw cat /root/.nix-channels
```

## 启动日志

容器启动时会显示 Nix 环境状态:

```bash
docker compose logs | grep -i nix
```

预期输出:
```
[Nix] Nix already installed (loaded from persistent volume)
[Nix] Linking binaries from /nix/store/...
[Nix] Profile added to PATH (X packages available)
[Nix] Setup complete, proceeding to original entrypoint...
```

## 数据位置

Volume 数据存储在 Docker 的默认位置:

- **Linux**: `/var/lib/docker/volumes/qwenpaw-root/_data`
- **macOS (Docker Desktop)**: Docker VM 内部

## 备份和迁移

### 备份

```bash
# 导出 Volume 数据
docker run --rm -v qwenpaw-root:/data -v $(pwd):/backup \
  alpine tar czf /backup/qwenpaw-root-backup.tar.gz -C /data .

# 或创建快照
docker compose down
docker run --rm -v qwenpaw-root:/data -v $(pwd):/backup \
  alpine cp -r /data /backup/qwenpaw-root-snapshot
```

### 恢复

```bash
# 导入 Volume 数据
docker run --rm -v qwenpaw-root:/data -v $(pwd):/backup \
  alpine tar xzf /backup/qwenpaw-root-backup.tar.gz -C /data
```

### 迁移到新主机

```bash
# 1. 在旧主机备份
docker run --rm -v qwenpaw-root:/data -v $(pwd):/backup \
  alpine tar czf /backup/qwenpaw-root.tar.gz -C /data .

# 2. 传输到新主机
scp qwenpaw-root.tar.gz user@newhost:/tmp/

# 3. 在新主机恢复
docker volume create qwenpaw-root
docker run --rm -v qwenpaw-root:/data -v /tmp:/backup \
  alpine tar xzf /backup/qwenpaw-root.tar.gz -C /data
```

## 清理

如果需要重置 `/root` 目录:

```bash
# 停止容器
docker compose down

# 删除 Volume (警告: 将丢失所有数据!)
docker volume rm qwenpaw-root

# 重新启动 (会创建新的空 Volume)
docker compose up -d
```

## 与 Nix Store 的关系

项目中配置了两个相关的 Volume:

1. **qwenpaw-nix** (`/nix`)
   - Nix Store: 实际软件包文件
   - 只读的包存储
   - 较大 (数百 MB 到数 GB)

2. **qwenpaw-root** (`/root`)
   - Nix Profile: 符号链接到 Store
   - 用户配置和数据
   - 较小 (数十 MB)

两者配合工作:
- `/nix/store/` 包含实际的包文件
- `/root/.nix-profile/` 包含指向 Store 的符号链接
- 两者都需要持久化以保持完整状态

## 优势

✅ **包状态保持**: 重启后已安装的 Nix 包立即可用  
✅ **配置保持**: 用户的 shell 配置和环境设置不丢失  
✅ **快速启动**: 无需重新安装软件包  
✅ **数据隔离**: 容器重建不影响用户数据  
✅ **易于备份**: 可以独立备份用户数据  

## 注意事项

1. **权限问题**: Volume 挂载为 root 用户,确保有正确权限
2. **磁盘空间**: 定期检查 Volume 大小,避免占用过多空间
3. **备份策略**: 建议定期备份重要配置和数据
4. **安全考虑**: Volume 包含用户凭证等敏感信息,妥善保管

## 相关文件

- Docker 配置: `docker-compose.yml`
- 启动脚本: `nix/entrypoint.sh`
- Nix 配置: `nix/shell.nix`
- Nix 文档: `nix/README.md`
