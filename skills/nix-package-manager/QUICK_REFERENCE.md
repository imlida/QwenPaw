# Nix 快速参考

## 常用软件包名称

### 开发语言
- `python311` - Python 3.11
- `python312` - Python 3.12
- `nodejs-18_x` - Node.js 18
- `nodejs-20_x` - Node.js 20
- `go` - Go 语言
- `rustup` - Rust 工具链

### 开发工具
- `git` - 版本控制
- `tmux` - 终端复用器
- `vim` - 文本编辑器
- `htop` - 进程监控
- `jq` - JSON 处理
- `curl` - HTTP 客户端
- `wget` - 下载工具

### 系统工具
- `coreutils` - 核心工具集
- `findutils` - 文件查找工具
- `diffutils` - 文件比较工具
- `gzip` - 压缩工具

## 快速命令

```bash
# 安装单个包
nix-env -iA nixpkgs.<name>

# 安装多个包
nix-env -iA nixpkgs.{git,tmux,htop}

# 查看已安装
nix-env -q

# 卸载包
nix-env -e <name>

# 运行已安装的包
/root/.nix-profile/bin/<command>

# 加载到 PATH
export PATH=/root/.nix-profile/bin:$PATH
```

## Shell.nix 模板

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = [
    pkgs.git
    pkgs.tmux
    pkgs.htop
    pkgs.python311
    pkgs.nodejs-18_x
  ];
}
```
