#!/bin/bash
set -e

# ============================================
# Nix 环境初始化
# ============================================

# 配置 Nix 以在容器环境中运行 (无 nixbld 组)
mkdir -p /etc/nix
if [ ! -f /etc/nix/nix.conf ]; then
  echo 'build-users-group =' > /etc/nix/nix.conf
  echo "[Nix] Configuration created for container environment"
fi

# 确保 /root 目录存在并有正确权限 (持久化 Volume)
mkdir -p /root
chmod 700 /root 2>/dev/null || true

# 检查 Nix 是否已安装 (通过检查持久化 Volume 中的文件)
if [ ! -f /nix/var/nix/profiles/default/bin/nix-env ] && [ ! -f /nix/store/*nix-*/bin/nix ]; then
  echo "[Nix] Installing Nix package manager..."
  
  # 在容器中以 root 用户安装 Nix
  mkdir -p /nix
  
  # 下载并安装 Nix (容器环境特殊处理)
  export NIX_INSTALLER_NO_MODIFY_PROFILE=1
  sh <(curl -L https://nixos.org/nix/install) --no-daemon --no-channel-add || {
    echo "[Nix] Standard installation failed, trying alternative method..."
    
    # 备用方案: 手动解压安装
    curl -L https://releases.nixos.org/nix/nix-2.34.6/nix-2.34.6-aarch64-linux.tar.xz -o /tmp/nix.tar.xz
    mkdir -p /nix/store
    tar -xJf /tmp/nix.tar.xz --strip-components=1 -C /nix/store
    
    # 创建基本配置
    mkdir -p /nix/var/nix/profiles
    mkdir -p /nix/var/nix/gcroots
    mkdir -p /nix/var/nix/temproots
    mkdir -p /nix/var/nix/userpool
    mkdir -p /nix/var/nix/profiles/per-user/root
    
    # 创建 profile
    ln -sf /nix/store/nix-2.34.6 /nix/var/nix/profiles/default
    
    echo "[Nix] Alternative installation complete"
  }
  
  rm -f /tmp/nix.tar.xz
  echo "[Nix] Installation complete"
else
  echo "[Nix] Nix already installed (loaded from persistent volume)"
fi

# 创建 Nix 命令的符号链接 (如果不存在)
if [ ! -f /usr/local/bin/nix ]; then
  NIX_BIN=$(find /nix/store -maxdepth 1 -name '*nix-2.*' -type d 2>/dev/null | head -1)
  if [ -n "$NIX_BIN" ]; then
    echo "[Nix] Linking binaries from $NIX_BIN"
    ln -sf "$NIX_BIN/bin/nix" /usr/local/bin/nix 2>/dev/null || true
    ln -sf "$NIX_BIN/bin/nix-env" /usr/local/bin/nix-env 2>/dev/null || true
    ln -sf "$NIX_BIN/bin/nix-shell" /usr/local/bin/nix-shell 2>/dev/null || true
    ln -sf "$NIX_BIN/bin/nix-channel" /usr/local/bin/nix-channel 2>/dev/null || true
    ln -sf "$NIX_BIN/bin/nix-collect-garbage" /usr/local/bin/nix-collect-garbage 2>/dev/null || true
  fi
fi

# 加载 Nix profile 到 PATH (持久化在 /root/.nix-profile)
if [ -d /root/.nix-profile/bin ]; then
  export PATH="/root/.nix-profile/bin:$PATH"
  echo "[Nix] Profile added to PATH ($(ls /root/.nix-profile/bin/ | wc -l) packages available)"
else
  echo "[Nix] No profile found, will be created on first package install"
fi

# ============================================
# 可选: 自动激活声明式环境 (如果存在 shell.nix)
# ============================================

if [ -f /app/nix-config/shell.nix ]; then
  echo "[Nix] Found shell.nix, environment will be available via: nix-shell /app/nix-config/shell.nix"
fi

echo "[Nix] Setup complete, proceeding to original entrypoint..."

# ============================================
# 执行原始 entrypoint (保持原有功能)
# ============================================
# 原始的 /entrypoint.sh 会:
# 1. 使用 envsubst 替换 supervisord 配置中的 QWENPAW_PORT
# 2. 启动 supervisord 管理 QwenPaw 进程
exec /entrypoint.sh "$@"
