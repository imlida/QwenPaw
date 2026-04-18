# Nix 包管理使用指南

## 快速开始

### 1. 启动容器

```bash
docker compose up -d
```

首次启动时会自动下载并安装 Nix (~1-2 分钟),后续启动会直接使用持久化的 Volume。

### 2. 查看启动日志

```bash
docker compose logs -f
```

你应该能看到类似输出:
```
[Nix] Installing Nix package manager...
[Nix] Installation complete
[Nix] Environment loaded
[Nix] Setup complete, proceeding to original entrypoint...
```

## 使用 Nix 安装软件包

### 方式一: 命令式安装 (适合临时测试)

```bash
# 进入容器
docker exec -it qwenpaw bash

# 加载 Nix 环境
. ~/.nix-profile/etc/profile.d/nix.sh

# 安装软件包
nix-env -iA nixpkgs.python311
nix-env -iA nixpkgs.nodejs-18_x
nix-env -iA nixpkgs.git

# 查看已安装的包
nix-env -q

# 使用软件包
python3 --version
node --version
```

### 方式二: 声明式安装 (推荐,适合生产环境)

1. 编辑 `nix/shell.nix`,添加需要的软件包:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = [
    pkgs.python311
    pkgs.nodejs-18_x
    pkgs.git
    pkgs.tmux
    pkgs.htop
  ];
  
  shellHook = ''
    echo "Nix environment loaded"
  '';
}
```

2. 重启容器:
```bash
docker compose down
docker compose up -d
```

3. 在容器内激活环境:
```bash
docker exec -it qwenpaw bash
nix-shell /app/nix-config/shell.nix
```

## 常用 Nix 命令

```bash
# 加载 Nix 环境 (每次进入容器都需要执行)
. ~/.nix-profile/etc/profile.d/nix.sh

# 搜索软件包
nix search nixpkgs python

# 安装软件包
nix-env -iA nixpkgs.<package-name>

# 查看已安装的包
nix-env -q

# 卸载软件包
nix-env -e <package-name>

# 更新所有软件包
nix-env -u

# 回滚到上一个版本
nix-env --rollback

# 清理未使用的包
nix-collect-garbage -d
```

## 持久化验证

```bash
# 1. 安装一个软件包
docker exec -it qwenpaw bash -c "
  . ~/.nix-profile/etc/profile.d/nix.sh
  nix-env -iA nixpkgs.hello
"

# 2. 重启容器
docker compose restart

# 3. 验证软件包依然存在
docker exec -it qwenpaw bash -c "
  . ~/.nix-profile/etc/profile.d/nix.sh
  hello
"
# 输出: Hello, world!
```

## 注意事项

1. **首次启动较慢**: 需要下载 Nix (~500MB),后续启动很快
2. **磁盘空间**: Nix Store 会占用一定空间,定期运行 `nix-collect-garbage -d` 清理
3. **环境变量**: 每次进入容器都需要加载 Nix 环境: `. ~/.nix-profile/etc/profile.d/nix.sh`
4. **官方镜像**: 完全使用官方镜像,未做任何修改

## 故障排查

### Nix 安装失败

```bash
# 查看完整日志
docker compose logs

# 重新安装 (删除 Volume 后重启)
docker compose down
docker volume rm qwenpaw-nix
docker compose up -d
```

### 软件包找不到

确保已加载 Nix 环境:
```bash
. ~/.nix-profile/etc/profile.d/nix.sh
which nix-env
```

### Volume 权限问题

```bash
# 检查 Volume 状态
docker volume inspect qwenpaw-nix
```
