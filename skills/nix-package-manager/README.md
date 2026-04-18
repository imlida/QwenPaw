# Nix Package Manager Skill

## 概述

这个 Skill 指导 AI 在 QwenPaw 容器**内部**使用 Nix 包管理器安装和管理软件包。

## 触发场景

当以下情况出现时,AI 会自动应用此 Skill:

- 用户要求使用 Nix 安装软件包
- 提到 `nix-env`、`nix-shell`、`nixpkgs` 等命令
- 容器环境中缺少必要的开发工具
- 需要配置开发环境或工具链

## 文件结构

```
nix-package-manager/
├── SKILL.md              # 主要技能文件 (226 行)
└── QUICK_REFERENCE.md    # 快速参考手册
```

## 功能特性

✅ **环境检测**: 自动检测 Nix 环境是否可用  
✅ **两种安装方式**: 命令式 (临时测试) 和声明式 (生产推荐)  
✅ **软件包运行**: 处理 Nix profile 路径问题  
✅ **持久化支持**: 验证容器重启后软件包不丢失  
✅ **常见问题解决**: 包含 FAQ 和故障排除  
✅ **最佳实践**: 提供推荐的工作流程  
✅ **容器内部使用**: 所有命令直接在容器内运行,无需 docker 命令  

## 使用示例

### 示例 1: 安装 Python

用户说: "帮我在容器中安装 Python"

AI 会:
1. 使用 `nix-env -iA nixpkgs.python311` 安装
2. 通过 `/root/.nix-profile/bin/python3` 验证
3. 建议更新 `/app/nix-config/shell.nix` 记录依赖

### 示例 2: 安装开发工具链

用户说: "我需要 git、tmux 和 htop"

AI 会:
1. 批量安装这些工具
2. 验证每个工具是否可用
3. 提供使用示例

### 示例 3: 搜索软件包

用户说: "有没有 Node.js 18?"

AI 会:
1. 使用 `nix search nixpkgs nodejs` 搜索
2. 提供准确的包名称
3. 执行安装

## 核心命令速查

```bash
# 安装软件包
nix-env -iA nixpkgs.<name>

# 查看已安装
nix-env -q

# 运行软件包
/root/.nix-profile/bin/<command>

# 加载到 PATH
export PATH=/root/.nix-profile/bin:$PATH

# 清理空间
nix-collect-garbage -d
```

## 注意事项

1. **路径问题**: Nix 安装的软件在 `/root/.nix-profile/bin/`
2. **持久化**: 软件包保存在 `qwenpaw-nix` Volume 中
3. **首次使用**: 需要先运行 `nix-channel --update`
4. **容器环境**: Nix 配置为无 nixbld 组模式运行
5. **无 docker 命令**: 此 Skill 在容器内部使用,不依赖 docker 命令
6. **直接运行**: 所有命令直接在容器内执行,无需 `docker exec`

## 相关资源

- 项目中的 Nix 配置: `/app/nix-config/` (容器内路径)
- 入口脚本: `/app/nix-config/entrypoint.sh` (容器内路径)
- Docker 配置: `docker-compose.yml` (宿主机路径)
