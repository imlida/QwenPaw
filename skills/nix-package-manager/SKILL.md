---
name: nix-package-manager
description: Install and manage software packages using Nix inside the QwenPaw container. Use when the user asks to install packages via Nix, mentions nix-env/nix-shell/nixpkgs, needs development tools, or when required dependencies are missing in the container environment.
---

# Nix Package Manager

在 QwenPaw 容器内部使用 Nix 安装和管理软件包的指南。

## 环境检测

容器启动时已自动配置 Nix,使用前需确认:

```bash
# 检查 Nix 是否可用
nix --version

# 检查 Nix 命令路径
which nix
```

如果命令不可用,需要先创建符号链接:

```bash
# 查找 Nix 安装路径
NIX_BIN=$(find /nix/store -maxdepth 1 -name '*nix-2.*' -type d | head -1)

# 创建符号链接
ln -sf $NIX_BIN/bin/nix /usr/local/bin/nix
ln -sf $NIX_BIN/bin/nix-env /usr/local/bin/nix-env
ln -sf $NIX_BIN/bin/nix-channel /usr/local/bin/nix-channel
ln -sf $NIX_BIN/bin/nix-shell /usr/local/bin/nix-shell
```

## 安装软件包

### 前置准备 (首次使用)

```bash
# 添加 channel
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs

# 更新 channel 元数据
nix-channel --update
```

### 方式一: 命令式安装 (适合临时测试)

```bash
# 安装单个软件包
nix-env -iA nixpkgs.<package-name>

# 示例: 安装常用工具
nix-env -iA nixpkgs.python311
nix-env -iA nixpkgs.nodejs-18_x
nix-env -iA nixpkgs.git
nix-env -iA nixpkgs.tmux
nix-env -iA nixpkgs.htop

# 批量安装
nix-env -iA nixpkgs.{git,tmux,htop,jq}
```
### 方式二: 声明式安装 (推荐)

编辑 `/app/nix-config/shell.nix`,声明需要的软件包:

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

激活环境:
```bash
nix-shell /app/nix-config/shell.nix
```

## 运行已安装的软件包

Nix 安装的软件包位于 `/root/.nix-profile/bin/`:

```bash
# 方式 1: 使用完整路径 (推荐,适合脚本)
/root/.nix-profile/bin/python3 --version
/root/.nix-profile/bin/node --version

# 方式 2: 加载 profile 到 PATH (适合交互式使用)
export PATH=/root/.nix-profile/bin:$PATH
python3 --version
node --version

# 方式 3: 在 shell.nix 中自动加载
nix-shell /app/nix-config/shell.nix
```

## 常用命令

```bash
# 查看已安装的包
nix-env -q

# 搜索软件包
nix search nixpkgs <keyword>

# 卸载软件包
nix-env -e <package-name>

# 更新所有软件包
nix-env -u

# 回滚到上一个版本
nix-env --rollback

# 清理未使用的包 (释放空间)
nix-collect-garbage -d
```

## 持久化验证

Nix Store 通过 Docker Volume (`qwenpaw-nix`) 持久化,容器重启后软件包不会丢失:

```bash
# 安装软件包
nix-env -iA nixpkgs.hello

# 验证安装
/root/.nix-profile/bin/hello
# 输出: Hello, world!

# 容器重启后验证 (软件包依然存在)
# 重启后直接运行
/root/.nix-profile/bin/hello
```

## 搜索软件包

### 在线搜索
访问 https://search.nixos.org/packages 查找可用软件包

### 命令行搜索
```bash
nix search nixpkgs python
nix search nixpkgs nodejs
```

## 常见问题

### 1. nix-env 报错 "attribute not found"

需要先更新 channel:
```bash
nix-channel --update
```

### 2. 软件包安装失败

检查 Nix 配置:
```bash
cat /etc/nix/nix.conf
# 应包含: build-users-group =
```

如果配置缺失,创建它:
```bash
mkdir -p /etc/nix
echo 'build-users-group =' > /etc/nix/nix.conf
```

### 3. 找不到已安装的命令

软件包安装在 `/root/.nix-profile/bin/`,需要:
```bash
# 使用完整路径
/root/.nix-profile/bin/<command>

# 或加载到 PATH
export PATH=/root/.nix-profile/bin:$PATH
```

### 4. 磁盘空间不足

清理未使用的 Nix 包:
```bash
nix-collect-garbage -d
```

### 5. Nix 命令找不到

创建符号链接:
```bash
NIX_BIN=$(find /nix/store -maxdepth 1 -name '*nix-2.*' -type d | head -1)
ln -sf $NIX_BIN/bin/nix /usr/local/bin/nix
ln -sf $NIX_BIN/bin/nix-env /usr/local/bin/nix-env
```

## 最佳实践

1. **优先使用声明式配置**: 在 `/app/nix-config/shell.nix` 中声明所有依赖,便于版本控制
2. **使用完整路径运行**: 在脚本中使用 `/root/.nix-profile/bin/<command>` 避免 PATH 问题
3. **定期清理**: 运行 `nix-collect-garbage -d` 清理旧版本释放空间
4. **验证安装**: 安装后立即测试命令是否可用
5. **记录依赖**: 将安装的软件包名称记录在 `shell.nix` 中

## 示例工作流

### 安装 Python 开发环境

```bash
# 1. 安装 Python 和相关工具
nix-env -iA nixpkgs.python311
nix-env -iA nixpkgs.python311Packages.pip
nix-env -iA nixpkgs.python311Packages.virtualenv

# 2. 验证安装
/root/.nix-profile/bin/python3 --version
/root/.nix-profile/bin/pip --version

# 3. 更新 shell.nix 记录依赖
# 编辑 /app/nix-config/shell.nix 添加 pkgs.python311
```

### 安装 Node.js 开发环境

```bash
# 1. 安装 Node.js
nix-env -iA nixpkgs.nodejs-18_x

# 2. 验证安装
/root/.nix-profile/bin/node --version
/root/.nix-profile/bin/npm --version

# 3. 使用 (加载到 PATH)
export PATH=/root/.nix-profile/bin:$PATH
npm install -g <package>
```

### 安装开发工具链

```bash
# 批量安装常用工具
nix-env -iA nixpkgs.{git,tmux,htop,jq,curl}

# 验证
/root/.nix-profile/bin/git --version
/root/.nix-profile/bin/tmux -V
/root/.nix-profile/bin/htop --version
```

## 注意事项

- 容器环境中 Nix 运行在 root 用户下
- 软件包持久化在 `qwenpaw-nix` Volume 中,容器重启后不丢失
- 首次安装 channel 需要下载元数据 (~100MB)
- 软件包安装路径: `/root/.nix-profile/bin/`
- Nix 配置路径: `/etc/nix/nix.conf` (必须包含 `build-users-group =`)
- shell.nix 路径: `/app/nix-config/shell.nix`
