# Nix 包管理方案 - 验证测试报告

## 测试时间
2026-04-18

## 测试结果

### ✅ 测试 1: Nix 安装
- **状态**: 通过
- **版本**: Nix 2.34.6
- **安装方式**: 容器内自动安装 (备用方案)
- **路径**: `/nix/store/ryr7lng2ippsrqlf7vh03f9ramad33id-nix-2.34.6`

### ✅ 测试 2: 软件包安装
- **状态**: 通过
- **测试包**: hello-2.12.3
- **安装命令**: `nix-env -iA nixpkgs.hello`
- **已安装包**:
  - hello-2.12.3
  - nix-2.34.6

### ✅ 测试 3: 软件包执行
- **状态**: 通过
- **测试结果**: `Hello, world!`
- **执行路径**: `/root/.nix-profile/bin/hello`

### ✅ 测试 4: Volume 持久化
- **状态**: 通过
- **Volume 名称**: qwenpaw-nix
- **挂载点**: `/var/lib/docker/volumes/qwenpaw-nix/_data`
- **容器内路径**: `/nix`
- **验证**: 容器重启后软件包依然存在

### ✅ 测试 5: QwenPaw 应用运行
- **状态**: 通过
- **Supervisord**: 运行中 (PID 1)
- **Web 服务**: 正常运行在端口 8088
- **访问测试**: 成功返回 HTML 页面

### ✅ 测试 6: Nix 配置
- **状态**: 通过
- **配置文件**: `/etc/nix/nix.conf`
- **关键配置**: `build-users-group =` (容器环境特殊配置)

## 架构验证

### 容器启动流程
```
1. Docker 启动容器
2. 执行自定义 entrypoint (/app/nix-config/entrypoint.sh)
3. 创建 Nix 配置 (build-users-group =)
4. 检查 Nix 是否已安装 → 从 Volume 加载
5. 创建 Nix 命令符号链接到 /usr/local/bin
6. 加载 Nix profile 到 PATH
7. exec /entrypoint.sh (原始脚本)
8. supervisord 启动 QwenPaw 应用
```

### 文件结构
```
nix/
├── shell.nix          # 软件包声明配置
├── default.nix        # Nix 环境配置
├── entrypoint.sh      # 自定义启动脚本 (已更新)
└── README.md          # 使用指南

docker-compose.yml     # 已添加 Nix Volume 和 entrypoint
```

## 使用示例

### 安装软件包
```bash
# 进入容器
docker exec -it qwenpaw bash

# 安装软件包
nix-env -iA nixpkgs.python311
nix-env -iA nixpkgs.nodejs-18_x
nix-env -iA nixpkgs.git

# 查看已安装的包
nix-env -q

# 运行软件包 (通过 profile 路径)
/root/.nix-profile/bin/python3 --version
```

### 声明式配置
编辑 `nix/shell.nix`:
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
}
```

### 清理无用包
```bash
nix-collect-garbage -d
```

## 优势总结

1. ✅ **不修改官方镜像**: 完全使用 `agentscope/qwenpaw:latest`
2. ✅ **持久化**: Nix Store 通过 Docker Volume 持久化
3. ✅ **可复现**: 支持声明式配置 (shell.nix)
4. ✅ **兼容性**: 原始 entrypoint 完整保留
5. ✅ **自动化**: 首次启动自动安装配置 Nix
6. ✅ **隔离性**: Nix 包与系统包隔离

## 注意事项

1. 首次启动会下载 Nix (~22MB),后续启动直接使用 Volume
2. 软件包安装在 `/root/.nix-profile/bin/` 目录下
3. 需要配置 `build-users-group =` 以在容器中运行
4. Nix Volume 会占用一定磁盘空间 (初始约 100MB)

## 后续优化建议

1. 可以预设常用 channel 以加快软件包安装
2. 可以考虑在 entrypoint 中自动加载 shell.nix 环境
3. 可以添加健康检查监控 Nix 环境状态
4. 可以配置 Nix 缓存以加速软件包安装

## 结论

✅ **所有测试通过**,方案可以正常使用!

Nix 包管理器已成功集成到 QwenPaw Docker 容器中,实现了:
- 软件包的持久化管理
- 容器重启后软件包不丢失
- QwenPaw 应用正常运行
- 原始功能完全保留
